#!/usr/bin/env perl
use strict;
use warnings;
use Template;
use File::Slurp qw(read_file);
use HTML::TreeBuilder::XPath;

sub main {
    my ($file) = @_;

    die "Need an html file to read\n" unless defined $file;
    die "Not a file: $file\n" unless -f $file;

    my $class = parse_html($file);
    output_pod($class);
}

sub parse_html {
    my ($file) = @_;

    my $class = {};

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_file($file);

    my $title = $tree->findvalue('/html/head/title');

    if ( $title =~ m#Box2D: (\w+) (Class|Struct) Reference#ms ) {
        $class->{name} = $1;
    }
    else {
        $class->{name} = 'TODO';
    }

    $class->{description} = $tree->findvalue('//div[@class="contents"]/p[4]');

    $class->{description} =~ s/\s+$//;

    # Use the first sentence from the description for the abstract
    if ( $class->{description} =~ /^((?:.*?)\.)/xs ) {
        $class->{abstract} = $1;
    }
    else {
        $class->{abstract} = 'TODO';
    }

    $class->{methods} = parse_methods( $class, $tree );

    my $has_constructor
        = grep { $_->{name} =~ /^new/ } @{ $class->{methods} };

    if ( $title =~ m#Struct# && !$has_constructor ) {
        my %constructor = (
            name        => 'new()',
            description => 'Default constructor.',
        );

        unshift @{ $class->{methods} }, \%constructor;
    }

    return $class;
}

sub parse_methods {
    my ( $class, $tree ) = @_;

    my @methods;

    my @members = $tree->findnodes('//div[@class="memitem"]');

    foreach my $member (@members) {

        my $member_name = $member->findvalue('.//td[@class="memname"]');
        my ( $type, $name ) = parse_method_name($member_name);

        my $desc = $member->findvalue('.//div[@class="memdoc"]');

        next if $name =~ m/\[protected\]/;
        next if $name =~ m/\[friend\]/;

        # Skip destructors
        next if $name =~ m/ ^ ~ /x;

        my $return;
        if ( $type && $type ne 'void' && $type ne 'virtual' ) {
            $type = "Box2D::$type" if $type =~ /^b2/;
            $return = "C<$type>";
        }

        my @p_types
            = $member->findnodes_as_strings('.//td[@class="paramtype"]');
        my @p_names
            = $member->findnodes_as_strings('.//td[@class="paramname"]/em');

        my @args;

        for ( 0 .. $#p_types ) {
            my $type = $p_types[$_];
            $type =~ s/\xa0$//;
            if ( $type =~ /b2/ ) {
                $type =~ s/^.*(b2\w+).*$/$1/;
                $type = "Box2D::$type";
            }
            push @args, { type => "C<$type>", name => $p_names[$_] };
        }

        if ( $name eq $class->{name} ) {
            $name = 'new';

            if ( !$desc ) {
                $desc = 'Constructor.'         if @args;
                $desc = 'Default constructor.' if !@args;
            }
        }

        if ( $desc =~ / ^ (.*) Returns: (.*) $ /x ) {
            $desc = $1;
            $return .= " - $2" if $return;
        }

        if ( $desc =~ / ^ (.*) Parameters: (.*) $ /x ) {
            $desc = $1;

            # XXX This works for one or two parameters, maybe more
            my ( $first, @rest ) = split /\s+(\w+)\xa0/, $2;

            my @arg_descs = ($first);

            if (@rest) {
                for ( 0 .. $#rest / 2 ) {
                    my $arg_desc
                        = $rest[ $_ * 2 ] . "\xa0" . $rest[ $_ * 2 + 1 ];
                    push @arg_descs, $arg_desc;
                }
            }

            foreach my $arg_chunk (@arg_descs) {
                my ( $arg_name, $arg_desc ) = split /\xa0/, $arg_chunk, 2;

                $arg_desc =~ s/\s+$//;

                foreach (@args) {
                    if ( $_->{name} eq $arg_name ) {
                        $_->{desc} = $arg_desc;
                    }
                }
            }
        }

        for (@args) {
            $_->{name} = '$' . $_->{name};
        }

        if (@args) {
            my @names = map { $_->{name} } @args;
            $name .= '( ' . join( ', ', @names ) . ' )';
        }
        else {
            $name .= '()';
        }

        for (@args) {
            $_->{name} = "C<$_->{name}>";
        }

        $desc   =~ s/\s+$// if $desc;
        $return =~ s/\s+$// if $return;

        my %method = (
            name        => $name,
            description => $desc,
        );

        $method{arguments} = \@args  if @args;
        $method{return}    = $return if $return;

        # XXX not all public members start with a lower case letter
        if ( !@args && $name ne 'new()' && $name =~ /^[a-z]/ ) {
            $method{attr} = 1;

            $method{return} = $return if $return;

            ( my $base = $method{name} ) =~ s/\(\)$//;

            $method{setter} = $base . '( $' . $base . ' )';

            my $arg_name = 'C<$' . $base . '> (optional)';

            $method{arguments} = [ { name => $arg_name } ];

            $method{arguments}->[0]->{type} = $method{return}
                if $method{return};
        }

        push @methods, \%method;
    }

    return \@methods;
}

sub parse_method_name {
    my ($name) = @_;

    # Parse things like:
    #   float Class::Method
    #   Class * Class::Method
    #   Class & Class::Method
    #   const Class * Class::Method
    #   const Class & Class::Method
    my $regex = qr/
        ^
        \s*
        (?:
            (?: virtual \s+ )?  # possibly virtual
            (?: const \s+ )?    # possibly const
            ( \w+ \*? )         # return type
            \s+
            (?: \* \s+)?        # possibly a pointer
            (?: & \s+)?         # possibly a reference
        )?
        (?: \w+ )               # class name
        ::
        ( ~? \w+ )              # method name
        \s*
        $
    /x;

    if ( $name =~ $regex ) {
        return ( $1, $2 );
    }
    else {
        return ( '', $name );
    }
}

sub output_pod {
    my ($class) = @_;
    my $tt = Template->new() or die "$Template::ERROR\n";
    $tt->process( \*DATA, $class ) or die $tt->error(), "\n";
}

main(@ARGV);

__END__

=head1 NAME

Box2D::[% name %] - [% abstract %]

=head1 SYNOPSIS

  # TODO

=head1 DESCRIPTION

[% description %]

=head1 METHODS
[% FOREACH method = methods %]
=head2 [% method.name %]
[% IF method.attr -%]

=head2 [% method.setter %]
[% END -%]
[% IF method.description -%]

[% method.description %]
[% END -%]
[% IF method.arguments -%]

Parameters:

=over 4
[% FOREACH arg = method.arguments %]
=item * [% arg.type %] [% arg.name %][% IF arg.desc %] - [% arg.desc %][% END %]
[% END %]
=back
[% END -%]
[% IF method.return %]
Returns a [% method.return %]
[% END -%]
[% END %]
=head1 SEE ALSO

=over 4

=item * L<Box2D>

=back

=head1 BUGS

See L<Box2D/BUGS>

=head1 AUTHORS

See L<Box2D/AUTHORS>

=head1 COPYRIGHT & LICENSE

See L<Box2D/"COPYRIGHT & LICENSE">

=cut
