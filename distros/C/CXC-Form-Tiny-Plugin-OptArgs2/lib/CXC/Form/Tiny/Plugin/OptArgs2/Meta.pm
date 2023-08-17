package CXC::Form::Tiny::Plugin::OptArgs2::Meta;

# ABSTRACT: Form metaclass role for OptArgs2

use v5.20;

use warnings;

our $VERSION = '0.04';

use Scalar::Util qw( blessed );
use Ref::Util 'is_plain_hashref';
use Form::Tiny::Utils 'get_package_form_meta';
use Types::Standard       qw( Bool CodeRef Dict Enum Int Optional Value );
use Type::Params          qw( signature_for );
use Types::Common::String qw ( NonEmptySimpleStr );

use Moo::Role;

use experimental 'signatures', 'postderef', 'lexical_subs';

use namespace::clean;

my sub croak {
    require Carp;
    goto \&Carp::croak;
}











has optargs => (
    is       => 'rwp',
    lazy     => 1,
    init_arg => undef,
    builder  => sub ( $self ) { $self->_build_opt_args->optargs },
);

has rename => (
    is       => 'rwp',
    lazy     => 1,
    init_arg => undef,
    builder  => sub ( $self ) { $self->_build_opt_args->rename },
);










sub rename_options ( $self, $opt ) {
    my $rename = $self->rename;
    for my $from ( keys $opt->%* ) {
        my $to = $rename->{$from};
        croak( "unexpected option key: $from\n" )
          if !defined $to;
        $opt->{$to} = delete $opt->{$from};
    }
}

sub _build_opt_args ( $self ) {
    my %rename;

    my @optargs;
    for my $aref ( $self->_create_options( \%rename )->@* ) {
        my ( $name, $spec ) = $aref->@*;
        my %spec = $spec->%*;
        delete $spec{order};
        push @optargs, $name, \%spec;
    }

    $self->_set_optargs( \@optargs );
    $self->_set_rename( \%rename );
    return $self;
}

# this has too many arguments
sub _create_options (
    $self, $rename,
    $path      = [],
    $opt_path  = [],
    $blueprint = $self->blueprint( recurse => 0 ),
  )
{

    my @optargs;

    for my $field ( sort keys $blueprint->%* ) {

        my $def = $blueprint->{$field};

        if ( is_plain_hashref( $def ) || ( my $is_subform = $def->is_subform ) ) {

            # Normally a sub-form's options get a prefix based on the field name, e.g.
            # db.opts => --db-opts.  Sometimes the extra levels are overkill for the option names,
            # so if the options entry contains 'name' specification, use that for the prefix.
            # unfortunately if the field name is nested, we only get here at the bottom of the
            # hierarchy, so need to backtrack.

            my @paths = ( [ $path->@*, $field ] );

            if ( $is_subform
                and defined( my $name = ( ( $def->addons->{ +__PACKAGE__ } // {} )->{optargs} // {} )->{name} ) )
            {
                my @comp  = split( /[.]/, $def->name );
                my @fixup = $opt_path->@*;
                if ( @fixup ) {
                    splice( @fixup, @fixup - @comp, @comp, $name );
                }
                else {
                    @fixup = ( $name );
                }
                push @paths, \@fixup;
            }
            else {
                push @paths, [ $opt_path->@*, $field ];
            }

            push @optargs,
              $is_subform
              ? get_package_form_meta( blessed $def->type )->_create_options( $rename, @paths )->@*
              : $self->_create_options( $rename, @paths, $def )->@*;

        }
        else {
            next unless defined( my $orig_optargs = $def->addons->{ +__PACKAGE__ }{optargs} );

            croak( "optargs initialized, but no option or argument specification for field $field?" )
              if !defined $orig_optargs->{spec};

            my $optargs = $orig_optargs->{spec};

            # This bit deals with creating the option name and then mapping it back onto the
            # Form::Tiny blueprint for the form, which may introduce extra layers in the
            # nested hash if the field name has multiple components.
            # Special cases arise:
            # 1) multi-component field name, e.g. 'output.parsed'
            # 2) options name ne field name, e.g. '--raw-output' ne 'output.raw'.
            # 3) field name has an underscore, which can get confused
            #    when the options are unflattened, as underscore is
            #    used to indicated nested structures


            # if @path > 1, then a multi-component name was given to form_field.
            # Form::Tiny doesn't keep track of sub-forms' parents, so it doesn't know
            # so we keep track of the entire path via $path.
            # we only need the last component to get the (leaf) form field name.
            my $field_name = $def->get_name_path->path->[-1];

            # this is the fully qualified normalized field name, with
            # components separated by NUL and will be used create the
            # correct hierarchy when the options hash is unflattened.
            my $fq_field_name = join( chr( 0 ), $path->@*, $field_name );

            # generate the fully qualified option name using the
            # specified field name.  the field may specify an
            # alternate option name, so use that if specified.
            my $fq_option_name = $optargs->{name} // join( '_', $opt_path->@*, $field_name );

            # store the mapping between option name and fully
            # qualified normalized field name.

            if ( defined( my $old_rename = $rename->{$fq_option_name} ) ) {
                croak( "redefined rename of $fq_option_name to $fq_field_name (originally to $old_rename)" );
            }
            $rename->{$fq_option_name} = $fq_field_name;

            $optargs->{default} = $def->default->()
              if $optargs->{show_default} && $def->has_default;

            push @optargs, [ $fq_option_name, $optargs ];
        }
    }

    ## no critic (BuiltinFunctions::RequireSimpleSortBlock)
    return [
        # no order, pass 'em through
        ( grep { !defined $_->[1]{order} } @optargs ),

        # order, sort 'em, but complain if multiple arguments with the
        # same order, as that is not deterministic
        (
            sort {
                my $order = $a->[1]{order} <=> $b->[1]{order};
                croak( "$a->[0] and $b->[0] have the same argument order" )
                  if $order == 0;
                $order;
              }
              grep { defined $_->[1]{order} } @optargs
        ) ];
}

my sub optarg ( $field, $spec ) {
    my $stash   = $field->addons->{ +__PACKAGE__ } //= {};
    my $optargs = ( $stash->{optargs} //= {} );
    croak( sprintf( 'duplicate definition for field %s', $field->name ) )
      if defined $optargs->{spec};

    $spec->{required} //= !!$field->required;
    $optargs->{spec} = $spec;
    return;
}

use constant OptionTypeEnums => qw( ArrayRef Flag Bool Counter HashRef Int Num Str );
use constant OptionTypeMap   => { map { $_ => "--$_" } OptionTypeEnums };

use constant OptionType => Enum( [ values OptionTypeMap->%* ] )
  ->plus_coercions( NonEmptySimpleStr, sub { /^--/ ? $_ : "--$_" } );

use constant ArgumentTypeEnums => qw( ArrayRef HashRef Int Num Str SubCmd );
use constant ArgumentType      => Enum [ArgumentTypeEnums];
use constant ArgumentTypeMap   => { map { $_ => $_ } ArgumentTypeEnums() };

sub _resolve_type ( $field, $type_set ) {

    # dynamic fields don't have types
    return undef
      unless defined $field
      && $field->isa( 'Form::Tiny::FieldDefinition' )
      && $field->has_type;

    my $type = $field->type;

    while ( defined $type ) {
        return $type_set->{ $type->name } if exists $type_set->{ $type->name };
        $type = $type->parent;
    }

    return undef;
}

signature_for _dsl_add_option => (
    method => 1,
    head   => 1,     # field context
    bless  => !!0,
    named  => [
        name         => Optional [NonEmptySimpleStr],
        alias        => Optional [NonEmptySimpleStr],
        comment      => NonEmptySimpleStr,
        default      => Optional [ Value | CodeRef ],
        required     => Optional [Bool],
        hidden       => Optional [Bool],
        isa          => Optional [OptionType],
        isa_name     => Optional [NonEmptySimpleStr],
        show_default => Optional [Bool],
        trigger      => Optional [CodeRef],
    ],
);
sub _dsl_add_option ( $self, $context, $spec ) {
    croak( q{The 'option' directive must be used after a field definition} )
      if !defined( $context );
    my %spec = $spec->%*;
    $spec{isa} //= _resolve_type( $context, OptionTypeMap )
      // croak( sprintf( q{'isa' attribute not specified or resolved for %s}, $context->name ) );
    optarg( $context, \%spec );
}

signature_for _dsl_add_argument => (
    method => 1,
    head   => 1,
    bless  => !!0,
    named  => [
        name         => Optional [NonEmptySimpleStr],
        comment      => NonEmptySimpleStr,
        default      => Optional [ Value | CodeRef ],
        greedy       => Optional [Bool],
        fallthru     => Optional [Bool],
        isa          => Optional [ArgumentType],
        isa_name     => Optional [NonEmptySimpleStr],
        required     => Optional [Bool],
        show_default => Optional [Bool],
        order        => Int,
    ],
);
sub _dsl_add_argument ( $self, $context, $spec ) {
    croak( q{The 'argument' directive must be used after a field definition} )
      if !defined( $context );
    my %spec = $spec->%*;
    $spec{isa} //= _resolve_type( $context, ArgumentTypeMap )
      // croak( sprintf( q{'isa' attribute not specified or resolved for %s}, $context->name ) );
    optarg( $context, \%spec );
}

#
# This file is part of CXC-Form-Tiny-Plugin-OptArgs2
#
# This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory optargs

=head1 NAME

CXC::Form::Tiny::Plugin::OptArgs2::Meta - Form metaclass role for OptArgs2

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This role is applied by L<CXC::Form::Tiny::Plugin::OptArgs2> to the
form's metaclass.  It adds two new DSL directives, C<option> and
C<argument>.  See L<CXC::Form::Tiny::Plugin::OptArgs2> for further
information.

=head1 METHODS

=head2 optargs

  \@optargs = $form_meta->optargs;

Return an array of option and argument specifications compatible with
the L<OptArgs2> C<optargs> option.

=head2 rename_options

  $form_meta->rename_options( \%options );

Rename I<in place> the names of the options as returned by
L<OptArgs2>.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-form-tiny-plugin-optargs@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Form-Tiny-Plugin-OptArgs>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-form-tiny-plugin-optargs

and may be cloned from

  https://gitlab.com/djerius/cxc-form-tiny-plugin-optargs.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Form::Tiny::Plugin::OptArgs2|CXC::Form::Tiny::Plugin::OptArgs2>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
