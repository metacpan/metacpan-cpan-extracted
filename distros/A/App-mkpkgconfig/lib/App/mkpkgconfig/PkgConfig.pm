package App::mkpkgconfig::PkgConfig;

# ABSTRACT: output pkg-config .pc files

use v5.10.0;

use Regexp::Common 'balanced';

use Moo;

use App::mkpkgconfig::PkgConfig::Entry;
use constant Keyword => 'App::mkpkgconfig::PkgConfig::Entry::Keyword';
use constant Variable => 'App::mkpkgconfig::PkgConfig::Entry::Variable';

our $VERSION = 'v2.0.0';

use IO::File   ();
use IO::Handle ();

sub croak {
    require Carp;
    goto &Carp::croak;
}

use namespace::clean;






has _keywords => (
    is        => 'ro',
    default   => sub { {} },
    init_args => 'keywords',
);

has _variables => (
    is        => 'ro',
    default   => sub { {} },
    init_args => 'variables',
);


















sub new_from {
    my $class = shift;
    my $file = shift;

    open( my $fh, '<', $file )
      or croak ("unable to open $file\n" );

    my $pkg  = $class->new;

    while ( defined( $_ = $fh->getline) ) {

        next if /^\s*#/; # ignore comments
        next if /^\s*$/; # ignore empty lines

        chomp;
        croak( "unable to parse line: $_\n" )
          unless /^[\s]*(?<name>[^\s:=]+)\s*(?<op>[:=])\s*(?<value>.*?)\s*(#.*)?$/;

        if ( $+{op} eq ':' ) {
            $pkg->add_keyword( $+{name} => $+{value} );
        }
        else {
            $pkg->add_variable( $+{name} => $+{value} );
        }
    }

    close $fh or croak;

    return $pkg;
}










sub variable {
    return $_[0]->_variables->{ $_[1] };
}









sub variables {
    return values %{ $_[0]->_variables };
}









sub keyword {
    return $_[0]->_keywords->{ $_[1] };
}










sub keywords {
    return values %{ $_[0]->_keywords };
}











sub add_variable {
    my ( $self, $name, $value ) = @_;

    croak ( "attempt to set $name to an undefined value\n" )
      unless defined $name;
    $self->_variables->{$name} = Variable->new( $name, $value );
}









sub add_variables {
    my ( $self, $variables ) = @_;

    $self->add_variable( $_, $variables->{$_} )
      for keys %{ $variables };
}










sub add_keyword {
    my ( $self, $name, $value ) = @_;

    croak ( "attempt to set $name to an undefined value\n" )
      unless defined $name;

    $self->_keywords->{$name} = Keyword->new( $name, $value );
}









sub add_keywords {
    my ( $self, $keywords ) = @_;

    $self->add_keyword( $_, $keywords->{$_} )
      for keys %{ $keywords };
}

































sub write {
    my ( $self, $file ) = ( shift, shift );

    my %options = (
                   vars => [],
                   write => 'all',
                   @_
                   );

    my $fh
      = defined $file
      ? IO::File->new( $file, 'w' )
      : IO::Handle->new_from_fd( fileno( STDOUT ), 'w' )
      or croak( "unable to create $file: $!\n" );

    if ( $options{comments} && @{ $options{comments} } ) {
        $fh->say( "# $_" ) for @{ $options{comments}};
        $fh->say();
    }

    my @entries = values %{ $self->_keywords };

    if ( $options{write} eq 'req' ) {

        if ( defined $options{vars} ) {
            push @entries, $self->_variables->{$_}
              // croak( "request for an undefined variable: $_\n" )
              for @{ $options{vars} };
        }
    }
    else {
        push @entries, values %{ $self->_variables };
    }

    my @vars_needed = $self->resolve_dependencies( @entries );

    $fh->say( "${_} = @{[ $self->_variables->{$_}->value ]}" )
      foreach $self->order_variables( @vars_needed );

    $fh->say();

    $fh->say( "${_}: @{[ $self->_keywords->{$_}->value ]}" )
      foreach order_keywords( keys %{ $self->_keywords } );

    return;
}

sub _entry_type {
    $_[0]->isa( Keyword ) ? "Keyword" : "Variable",
}











sub resolve_dependencies {
    my ( $self, @entries ) = @_;

    my %validated;
    use Hash::Ordered;

    # descend dependency tree.  use an ordered hash to keep track of
    # which variables are in the current tree, and an array of dependency
    # arrays to keep track of each variable's dependencies.  The ordered
    # hash makes it easy to generate human readable error output.

    # could have used an actual tree, but only need a fraction of the
    # functionality, and it's faster to check for duplicates in a hash
    # than to compare tree nodes.

    for my $entry ( @entries ) {
        my $track = Hash::Ordered->new;
        $track->push( $entry->name, undef );
        my @depends = ( [ $entry->depends ] );

        while ( @depends ) {

            # check dependencies for last variable
            while ( my $name = pop @{ $depends[-1] } ) {
                next if $validated{$name};

                if ( $track->exists( $name ) ) {
                    croak(
                        sprintf(
                            "%s '%s' has a circular dependency: %s\n",
                            _entry_type( $entry ),
                            $entry->name,
                            join( '->', $track->keys, $name ) ) );
                }

                my $var = $self->_variables->{$name} // croak(
                    sprintf(
                        "%s '%s' depends upon an undefined variable: %s\n",
                        _entry_type( $entry ),
                        $entry->name,
                        join( '->', $track->keys, $name, 'undef' ),
                    ) );

                $track->push( $name, undef );
                push @depends, [ $var->depends ];
            }

            my ( $name ) = $track->pop;
            $validated{$name} = undef;
            pop @depends;
        }

        delete $validated{$entry->name} if $entry->isa( Keyword );
    }

    return keys %validated;
}










sub order_variables {

    my ( $self, @needed ) = @_;

    return () unless @needed;

    @needed = do { my %uniqstr; @uniqstr{@needed} = (); keys %uniqstr; };

    my %dephash = map {
        $_ => [ ( $self->_variables->{$_} // croak( "unknown variable: $_\n" ) )->depends ] }
      @needed;

    require Algorithm::Dependency::Ordered;
    require Algorithm::Dependency::Source::HoA;

    my $ordered;

    eval {
        my $deps
          = Algorithm::Dependency::Ordered->new(
            source => Algorithm::Dependency::Source::HoA->new( \%dephash ) )
          or die( "error creating dependency object\n" );

        $ordered = $deps->schedule( @needed );

        if ( !defined $ordered ) {
            die( "error in variable dependencies: perhaps there's cycle?\n" ),;
        }
    };

    if ( length( my $err = $@ ) ) {
        require Data::Dumper;
        die( $err,
            Data::Dumper->Dump( [ \%dephash, \@needed ], [qw( deps needed )] ) );
    }

    # move variables with no dependencies to the beginning of the list
    # to make it more human friendly
    my @nodeps = sort grep { !@{ $dephash{$_} } } @$ordered;


    if ( @nodeps ) {
        my %nodeps;
        @nodeps{@nodeps} = ();
        $ordered = [ @nodeps, grep { !exists $nodeps{$_} } @$ordered ];
    }

    return @{$ordered};
}










sub order_keywords {
    my ( @keywords ) = @_;

    my %keywords;
    @keywords{ @keywords } = ();

    my @first_keys
      = grep { exists $keywords{$_} } qw( Name Description Version );
    my %last_keys;
    @last_keys{ @keywords } = ();
    delete @last_keys{@first_keys};

    return @first_keys, keys %last_keys;
}

1;

#
# This file is part of App-mkpkgconfig
#
# This software is Copyright (c) 2020 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory pc

=head1 NAME

App::mkpkgconfig::PkgConfig - output pkg-config .pc files

=head1 VERSION

version v2.0.0

=head1 SYNOPSIS

  # create an empty object
  $pkg = PkgConfig->new;

  # Construct an object from an existing .pc file
  $obj = PkgConfig->new_from( $file );

  # or from a string containing similar content
  $obj = PkgConfig->new_from( \$string );

  # add a keyword
  $obj->add_keyword( $name, $value );

  # add a variable
  $obj->add_variable( $name $value );

  # resolve_dependencies for one or more keywords or variables:

  @var_names = $obj->resolve_depdencies( $obj->keyword('Version') );

  # write out a .pc file
  $obj->write( $file );

=head1 DESCRIPTION

C<PkgConfig> manages keywords and variables for C<pkg-config> metadata
about a project.  It automatically scans values for variable
dependencies and can determine if there are dependency loops or
missing dependencies. It can generate a list of variables in the
correct order to resolve dependencies.

On top of this, it can read and write C<pkg-config> files.  Reading is
success oriented.

=head1 METHODS

=head2 new

  $obj = PkgConfig->new;

Construct an empty object

=head2 new_from

  $obj = PkgConfig->new_from( $file );
  $obj = PkgConfig->new_from( \$string );

Construct an object from an existing B<pkg-config> file or from a string containing similar content.

=head2 variable

   $variable = $obj->variable( $name) ;

Return a L<App::mkpkgconfig::PkgConfig::Entry::Variable> object for the requested variable.

=head2 variables

   @variables = $obj->variables;

Return a L<list of App::mkpkgconfig::PkgConfig::Entry::Variable> objects;

=head2 keyword

   $keyword = $obj->keyword( $name );

Return a L<App::mkpkgconfig::PkgConfig::Entry::Keyword> object for the requested keyword.

=head2 keywords

   @keywords = $obj->keywords;

Return a L<list of App::mkpkgconfig::PkgConfig::Entry::Keywords> objects;

=head2 add_variable

  $obj->add_variable( $name, $value );

Add a variable with the specified value.  If the variable exists, its
value will be updated.

=head2 add_variables

  $obj->add_variables( \%variables );

Add multiple variables, with names and values specified by the passed hash.

=head2 add_keyword

  $obj->add_keyword( $name, $value );

Add a keyword with the specified value.  If the keyword exists, its
value will be updated.

=head2 add_keywords

  $obj->add_keywords( \%keywords );

Add multiple keywords, with names and values specified by the passed hash.

=head2 write

  $obj->write( $file, %options );

Output C<pkg-config> metadata.  If C<< $file >> is undefined, the output will
be written to the standard output stream, otherwise to the specified file.
By default all of the keywords and variables will be output.

The available options are:

=over

=item comments => I<arrayref>

Write the comments at the top of the file, one per line.

=item write => C<all|req>

Which variables to output. If C<all> (the default), all are written.
If C<req>, write the variables required by the keywords as well as
those specified by the C<vars> option.

=item vars => I<arrayref>

If the C<write> option is C<req>, write the specified variables in
addition to those required by the keywords.

=back

=head2 resolve_dependencies

   @var_names = $obj->resolve_depdencies( @entries );

Returns the names of the variables needed to resolve all dependencies
in the passed list of L</App::mkpkgconfig::PkgConfig::Entry::Variable>
and L</App::mkpkgconfig::PkgConfig::Entry::Keyword> objects.

=head2 order_variables

  @ordered_variable_names = $obj->order_variables( @variable_names );

Return a list of variables names in the order that they should be evaluated to ensure that
dependencies are correctly resolved.

=head2 order_keywords

   @ordered_keywords = $obj->order_keywords( @keyword_names );

Return a list of keywords ordered so that the C<Name>, C<Description>,
and C<Version> keywords are at the beginning of the list.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-app-mkpkgconfig@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=App-mkpkgconfig

=head2 Source

Source is available at

  https://gitlab.com/djerius/app-mkpkgconfig

and may be cloned from

  https://gitlab.com/djerius/app-mkpkgconfig.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<script::mkpkgconfig|script::mkpkgconfig>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
