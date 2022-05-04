package CGI::Application::Plugin::RunmodeParseKeyword;
$CGI::Application::Plugin::RunmodeParseKeyword::VERSION = '0.14';
use warnings;
use strict;

=head1 NAME

CGI::Application::Plugin::RunmodeParseKeyword - Declare runmodes using Parse::Keyword

=cut

our @EXPORT = qw(runmode errormode startmode);
use Carp qw(croak);
use Sub::Name 'subname';
use Data::Dumper;
use Parse::Keyword {};

sub import {
    my $caller = caller;
    my $class = shift;
    my %args = @_;
    my $into = delete $args{into} || $caller;
    my $inv = delete $args{invocant} || '$self';

    Parse::Keyword->import( { runmode   => sub { my ($kw) = @_; parse_mode($kw, $inv); } } );
    Parse::Keyword->import( { errormode => sub { my ($kw) = @_; parse_mode($kw, $inv); } } );
    Parse::Keyword->import( { startmode => sub { my ($kw) = @_; parse_mode($kw, $inv); } } );

    for my $e(@EXPORT) {
        my $fn = $into . '::' . $e;
        no strict 'refs';
        *$fn = \&$e;
        *$fn if 0;
    }
}

sub runmode { @_ ? $_[0] : () }
sub errormode { @_ ? $_[0] : () }
sub startmode { @_ ? $_[0] : () }

my %REGISTRY;
sub _setup_runmode {
    my ($pkg, $name, $code) = @_;
    $pkg->add_callback( init => sub { $_[0]->run_modes([ $name ]) } );
}
sub _setup_startmode {
    my ($pkg, $name, $code) = @_;
    no strict 'refs'; no warnings 'uninitialized';
    # compile time check
    croak "start mode redefined (from $REGISTRY{$pkg}{start_mode_installed})" if $REGISTRY{$pkg}{start_mode_installed};
    $pkg->add_callback(
        init => sub {
            # run time check
            return if exists $_[0]->{__START_MODE_SET_BY_RUNMODEDECLARE};
            $_[0]->run_modes( [$name] );
            $_[0]->start_mode($name);
            $_[0]->{__START_MODE_SET_BY_RUNMODEDECLARE} = 1;
        }
    );
    $REGISTRY{$pkg}{start_mode_installed} = join '::', $pkg, $name;
}
sub _setup_errormode {
    my ($pkg, $name, $code) = @_;
    no strict 'refs'; no warnings 'uninitialized';
    croak "error mode redefined (from $REGISTRY{$pkg}{error_mode_installed})" if $REGISTRY{$pkg}{error_mode_installed};
    $pkg->add_callback(
        init => sub {
            return if exists $_[0]->{__ERROR_MODE_SET_BY_RUNMODEDECLARE};
            $_[0]->error_mode($name);
            $_[0]->{__ERROR_MODE_SET_BY_RUNMODEDECLARE} = 1;
        }
    );
    $REGISTRY{$pkg}{error_mode_installed} = join '::', $pkg, $name;
}

=begin pod-coverage

=over 4

=item parse_mode - we hook into this to install cgiapp callbacks

=item parse_name - identifier name parser

=item parse_signature - runmode signature parser

=item parse_attribute - parse one sub attr

=item parse_attributes - parse sub attrs

=item parse_body - parse code and inject defaults

=back

=end pod-coverage

=cut

sub parse_mode {
    my ($keyword, $invocant) = @_;

    my $name = parse_name();
    my $sig  = parse_signature($invocant);
    my $attr = parse_attributes();
    my $body = parse_body($sig);

    if (defined $name) {
        my $full_name = join('::', compiling_package, $name);
        {
            no strict 'refs';
            *$full_name = subname $full_name, $body;
            if ($attr) {
                use attributes ();
                attributes->import(compiling_package, $body, $_) for @$attr;
            }
            my $setup = '_setup_' . $keyword;
            $setup->(compiling_package, $name, $body);

        }
        return (sub {}, 1);
    }
    else {
        return (sub { $body }, 0);
    }
}

my $start_rx = qr/^[\p{ID_Start}_]$/;
my $cont_rx  = qr/^\p{ID_Continue}$/;

sub parse_name {
    my $name = '';

    lex_read_space;

    my $char_rx = $start_rx;

    while (1) {
        my $char = lex_peek;
        last unless length $char;
        if ($char =~ $char_rx) {
            $name .= $char;
            lex_read;
            $char_rx = $cont_rx;
        }
        else {
            last;
        }
    }

    return length($name) ? $name : undef;
}

sub parse_signature {
    my ($invocant_name) = @_;
    lex_read_space;

    my @vars = ({ index => 0, name => $invocant_name });
    return \@vars unless lex_peek eq '(';

    my @attr = ();

    lex_read;
    lex_read_space;

    if (lex_peek eq ')') {
        lex_read;
        return \@vars;
    }

    my $seen_slurpy;
    while ((my $sigil = lex_peek) ne ')') {
        my $var = {};
        die "syntax error"
            unless $sigil eq '$' || $sigil eq '@' || $sigil eq '%';
        die "Can't declare parameters after a slurpy parameter"
            if $seen_slurpy;

        $seen_slurpy = 1 if $sigil eq '@' || $sigil eq '%';

        lex_read;
        lex_read_space;
        my $name = parse_name(0);
        lex_read_space;

        $var->{name} = "$sigil$name";

        if (lex_peek eq '=') {
            lex_read;
            lex_read_space;
            $var->{default} = parse_arithexpr;
        }

        $var->{index} = @vars - 1;

        if (lex_peek eq ':') {
            $vars[0] = $var;
            lex_read;
            lex_read_space;
            next;
        }

        push @vars, $var;

        die "syntax error"
            unless lex_peek eq ')' || lex_peek eq ',';

        if (lex_peek eq ',') {
            lex_read;
            lex_read_space;
        }
    }

    lex_read;

    return \@vars;
}

# grabbed these two functions from
# https://metacpan.org/release/PEVANS/XS-Parse-Keyword-0.22/source/hax/lexer-additions.c.inc#L74
sub parse_attribute {
    my $name = parse_name;
    if (lex_peek ne '(') {
        return $name;
    }
    $name .= lex_peek;
    lex_read;
    my $count = 1;
    my $c = lex_peek;
    while($count && length $c) {
        if($c eq '(') {
            $count++;
        }
        if($c eq ')') {
            $count--;
        }
        if($c eq '\\') {
            # The next char does not bump count even if it is ( or );
            # the \\ is still captured
            #
            $name .= $c;
            lex_read;
            $c = lex_peek;
            if(! length $c) {
                goto unterminated;
            }
        }

        # Don't append final closing ')' on split name/val
        $name .= $c;
        lex_read;

        $c = lex_peek;
    }

    if(!length $c) {
        return;
    }

    return $name;

unterminated:
    croak("Unterminated attribute parameter in attribute list");
    return;
}

sub parse_attributes {
    lex_read_space;
    return unless lex_peek eq ':';
    lex_read;
    lex_read_space;
    my @attrs;
    while (my $attr = parse_attribute) {
        push @attrs, $attr;
        lex_read_space;
        if (lex_peek eq ':') {
            lex_read;
            lex_read_space;
        }
    }

    return \@attrs;
}

sub parse_body {
    my $sigs = shift;
    my $body;

    lex_read_space;

    if (lex_peek eq '{') {
        local $CAPRPK::{'DEFAULTS::'};
        if ($sigs) {
            lex_read;

            my $preamble = '{';

            # invocant
            my $inv = shift @$sigs;
            $preamble .= "my $inv->{name} = shift;";

            # arguments / query params
            my @names = map { $_->{name} } @$sigs;
            $preamble .= 'my (' . join(', ', @names) . ') = @_;';

            for my $name (@names) {
                my $s = substr($name,0,1);
                my $n = substr($name,1);
                if ($s eq '$') {
                    my $p = $inv->{name} . '->param("' . $n . '")';
                    $preamble .= $name . ' = ' . $p . ' unless ' . ( $s eq '$' ? 'defined ' : 'scalar ') . $name . ';';
                }
                my $p = $inv->{name} . '->query->' . ($s eq '@' ? 'multi_param' : 'param') . '("' . $n . '")';
                $preamble .= $name . ' = ' . $p . ' unless ' . ( $s eq '$' ? 'defined ' : 'scalar ') . $name . ';';
                if ($s eq '@') {
                    my $p = $inv->{name} . '->query->' . ($s eq '@' ? 'multi_param' : 'param') . '("' . $n . '[]")';
                    $preamble .= $name . ' = ' . $p . ' unless ' . ( $s eq '$' ? 'defined ' : 'scalar ') . $name . ';';
                }
            }

            my $index = 0;
            for my $var (grep { defined $_->{default} } @$sigs) {
                {
                    no strict 'refs';
                    *{ 'CAPRPK::DEFAULTS::default_' . $index } = sub () {
                        $var->{default}
                    };
                }
                $preamble .= $var->{name} . ' = CAPRPK::DEFAULTS::default_' . $index . '->()' . ' unless ' . $var->{name} . ';';

                $index++;
            }

            # warn $preamble . $/;
            lex_stuff($preamble);
        }
        $body = parse_block;
    }
    else {
        die "syntax error";
    }
    return $body;
}

1;

__END__

=head1 SYNOPSIS

    package My::CgiApp;

    use base 'CGI::Application';
    use CGI::Application::Plugin::RunmodeParseKeyword;

    startmode hello { "Hello!" }

    runmode world($name) {
        return $self->hello
        . ', '
        . $name || "World!";
    }

    errormode oops($c: $exception) {
        return "Something went wrong at "
        . $c->get_current_runmode
        . ". Exception: $exception";
    }

=head1 DESCRIPTION

This module allows you to declare run modes with a simple keyword. It provides
method signatures similar to L<Method::Signatures::Simple>.

It respects inheritance: run modes defined in the superclass are also available
in the subclass.

Beyond automatically registering the run mode, and providing C<$self>, it also
optionally pulls named parameters from C<< $self->query->param >> or
C<< $self->param >>.

=over 4

=item * Basic example

    runmode foo { $self->bar }

This declares the run mode "foo". Notice how C<$self> is ready for use.

=item * Rename invocant

    runmode bar ($c:) { $c->baz }

Same as above, only use C<$c> instead of C<$self>.

    use CGI::Application::Plugin::RunmodeParseKeyword invocant => '$c';
    runmode baz { $c->quux }

Same as above, but every runmode gets C<$c> by default. You can still say C<runmode ($self:)>
to rename the invocant.

=item * With a parameter list

    runmode baz ( $id, $name ) {
        return $self->wibble("I received $id and $name from a form submission
                              or a method invocation.");
    }

Here, we specify that the method expects two parameters, C<$id> and C<$name>.
Values can be supplied through a method call (e.g. C<< $self->baz(1, "me") >>),
or from the cgiapp object (e.g. C<< $self->param( id => 42 ) >>), or from the
query object (e.g. from C</script?id=42;name=me>).

=item * with default values for parameters

    runmode quux ($page = 1, $rows = 42) {
        ...
    }

Here we specify default values for the C<$page> and <$rows> parameters. These
defaults will be set in the absence of cgiapp params or query params.

=item * Code attributes

    runmode secret :Auth { ... }

Code attributes are supported as well.

=item * Combining with other ways to set run modes

This all works:

    sub setup {
        my $self = shift;
        $self->run_modes([ qw/ foo / ]);
    }

    sub foo {
        my $self = shift;
        return $self->other;
    }

    runmode bar {
        return $self->other;
    }

    sub other : Runmode {
        my $self = shift;
        return $self->param('other');
    }

So you can still use the classic way of setting up run modes, and you can
still use L<CGI::Application::Plugin::AutoRunmode>, *and* you can mix and match.

=back

=head1 EXPORT

=over 4

=item * errormode

Define the run mode that serves as C<< $self->error_mode >>. You can only declare one
C<errormode> per package.

=item * startmode

Define the run mode that serves as C<< $self->start_mode >>. You can only declare one
C<startmode> per package.

=item * runmode

Define run mode.

=back

=head1 AUTHOR

Rhesa Rozendaal, C<< <rhesa at cpan.org> >>

=head1 DIAGNOSTICS

=over 4

=item * error mode redefined (from %s) at %s line %s

You tried to install another errormode. Placeholders are filled with

 * fully qualified name of existing errormode
 * file name
 * line number

=item * start mode redefined (from %s) at %s line %s

You tried to install another startmode. Placeholders are filled with

 * fully qualified name of existing startmode
 * file name
 * line number

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-runmodeparsekeyword at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-RunmodeParseKeyword>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::RunmodeParseKeyword


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-RunmodeParseKeyword>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-RunmodeParseKeyword>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-RunmodeParseKeyword>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-RunmodeParseKeyword>

=back


=head1 ACKNOWLEDGEMENTS

Matt S. Trout for L<Devel::Declare>, and Michael G. Schwern for providing
the inspiration with L<Method::Signatures>.
Paul Knop for writing L<Parse::Keyword>. Even though it says DO NOT USE,
it works perfectly for this module.

=head1 COPYRIGHT & LICENSE

Copyright 2022 Rhesa Rozendaal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

