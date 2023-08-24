package CXC::Form::Tiny::Plugin::OptArgs2::Meta;

# ABSTRACT: Form metaclass role for OptArgs2

use v5.20;

use warnings;

our $VERSION = '0.08';

use Scalar::Util qw( blessed );
use Ref::Util    qw( is_plain_hashref is_arrayref is_regexpref is_ref );
use Form::Tiny::Utils 'get_package_form_meta';
use Types::Standard qw( ArrayRef Bool CodeRef Dict Enum Int Optional RegexpRef Tuple Undef Value );
use Type::Params    qw( signature_for );
use Types::Common::String qw ( NonEmptySimpleStr NonEmptyStr );

use Moo::Role;

use experimental 'signatures', 'postderef', 'lexical_subs';

use namespace::clean;

my sub croak {
    require Carp;
    goto \&Carp::croak;
}

# need to stash which form this field was added to in order to handle
# inheritance of inherited fields which aren't options, but which
# contain nested forms which *are* options.

around add_field => sub ( $orig, $self, @parameters ) {
    # this may return either a FieldDefinition or a FieldDefinition, but
    # in either case, it has an addons methods.
    my $field = $self->$orig( @parameters );
    $field->addons->{ +__PACKAGE__ }{package} = $self->package;
    return $field;
};








has inherit_required => (
    is      => 'rwp',
    isa     => Bool,
    builder => sub { !!1 },
);







has inherit_optargs => (
    is      => 'rwp',
    isa     => Bool,
    builder => sub { !!0 },
);









has inherit_optargs_match => (
    is      => 'rwp',
    isa     => Undef | ArrayRef [ Tuple [ Bool, RegexpRef ] ],
    builder => sub { undef },
);













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


















sub inflate_optargs ( $self, $optargs ) {

    state $folder = do {
        require Hash::Fold;
        Hash::Fold->new( delimiter => chr( 0 ) );
    };

    # make a copy of the flattened hash
    my %flat = $optargs->%*;

    # translate the OptArgs names into that required by the Form::Tiny structure
    $self->rename_options( \%flat );

    return $folder->unfold( \%flat );
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

my sub _match_inherit_optargs ( $matches, $package ) {

    my $excluded = 0;

    for my $match ( $matches->@* ) {
        my ( $retval, $qr ) = $match->@*;
        return $retval if $package =~ $qr;
        $excluded++ unless $retval;
    }

    # if no exclusions, then user forgot to add the exclude all
    # catch-all at the end.  just having inclusions doesn't make
    # sense.

    return $excluded != 0;
}

sub _inherit_optargs ( $self, $package ) {

    return $package eq $self->package
      || (
        $self->inherit_optargs
        && ( !defined $self->inherit_optargs_match
            || _match_inherit_optargs( $self->inherit_optargs_match, $package ) ) );
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

            my @paths = ( [ $path->@*, $field ], [ $opt_path->@*, $field ] );

            if ( $is_subform ) {

                my $addons = $def->addons->{ +__PACKAGE__ } // croak( 'no addons for field ' . $def->name );

                # bail if we're not inheriting
                next unless $self->_inherit_optargs( $addons->{package} );

                if ( defined( my $name = ( $addons->{optargs} // {} )->{name} ) ) {

                    ## no critic (ControlStructures::ProhibitDeepNests)
                    if ( my @fixup = $opt_path->@* ) {
                        my @comp = split( /[.]/, $def->name );
                        splice( @fixup, @fixup - @comp, @comp, $name );
                        # replace default opt_path
                        $paths[-1] = \@fixup;
                    }
                    else {
                        $paths[-1] = [$name];
                    }
                }

                push @optargs, get_package_form_meta( blessed $def->type )->_create_options( $rename, @paths )->@*;
            }

            else {
                push @optargs, $self->_create_options( $rename, @paths, $def )->@*;
            }

        }
        else {
            my $addons = $def->addons->{ +__PACKAGE__ } // croak( 'no addons for field ' . $def->name );
            next unless defined( my $orig_optargs = $addons->{optargs} );

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

            push @optargs, [ $fq_option_name, $optargs ]
              if $self->_inherit_optargs( $addons->{package} );
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

sub _add_optarg ( $self, $field, $spec ) {
    my $stash   = $field->addons->{ +__PACKAGE__ } //= {};
    my $optargs = ( $stash->{optargs} //= {} );
    croak( sprintf( 'duplicate definition for field %s', $field->name ) )
      if defined $optargs->{spec};

    $spec->{required} //= !!$field->required
      if $self->inherit_required;
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

    # take care of top level Any. Many other types inherit (eventually) from Any,
    # so the inheritance scan below will resolve types we don't support
    # if we add Any to OptionTypeMap and ArgumentTypeMap

    return $type_set->{Str}
      if $type->name eq 'Any';

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
    $self->_add_optarg( $context, \%spec );
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
    $self->_add_optarg( $context, \%spec );
}

use constant { INCLUDE => q{+}, EXCLUDE => q{-} };

my sub parse_inherit_matches ( $default, $entries ) {

    my @matches;
    my $include = $default;
    for my $entry ( $entries->@* ) {

        if ( is_arrayref( $entry ) ) {
            push @matches, __SUB__->( $include, $entry )->@*;
        }

        elsif ( is_regexpref( $entry ) ) {
            push @matches, [ $include eq INCLUDE, $entry ];
        }

        elsif ( $entry eq EXCLUDE || $entry eq EXCLUDE ) {
            $include = $entry;
            next;    # avoid reset of $include to default below
        }

        # every thing else is a regexp as a string; turn into a regexp
        else {
            push @matches, [ $include eq INCLUDE, qr/$entry/ ];
        }

        # reset include to default
        $include = $default;
    }

    return \@matches;
}


signature_for _dsl_optargs_opts => (
    method => 1,
    head   => 1,
    named  => [
        inherit_required      => Optional [Bool],
        inherit_optargs       => Optional [Bool],
        inherit_optargs_match => Optional [ArrayRef],
    ],
);
sub _dsl_optargs_opts ( $self, $context, $args ) {

    croak( q{The 'optargs_opts' directive must be used before any fields are defined} )
      if defined( $context );

    $self->_set_inherit_required( $args->inherit_required )
      if $args->has_inherit_required;

    $self->_set_inherit_optargs( $args->inherit_optargs )
      if $args->has_inherit_optargs;

    if ( $args->has_inherit_optargs_match ) {
        my $match = $args->inherit_optargs_match;
        $match = [$match] unless is_arrayref( $match );

        my $matches = parse_inherit_matches( INCLUDE, $match );
        $self->_set_inherit_optargs_match( $matches );
    }


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

version 0.08

=head1 DESCRIPTION

This role is applied by L<CXC::Form::Tiny::Plugin::OptArgs2> to the
form's metaclass.  It adds new DSL directives, C<optargs_opts>,
C<option>, and C<argument>.  See L<CXC::Form::Tiny::Plugin::OptArgs2> for
further information.

=head1 OBJECT ATTRIBUTES

=head2 inherit_required

If I<true>, the option inherits the 'require' attribute from the associated form field.
It defaults to I<true>.

=head2 inherit_optargs

If true, the output optargs will include those from forms which are superclasses of this one.

=head2 inherit_optargs_match

A regular expression which matches the class names of superclass forms
to exclude from inheritance.  It defaults to C<undef> which is
equivalent to matching everything.

=head1 METHODS

=head2 optargs

  \@optargs = $form_meta->optargs;

Return an array of option and argument specifications compatible with
the L<OptArgs2> C<optargs> option.

=head2 rename_options

  $form_meta->rename_options( \%options );

Rename I<in place> the names of the options as returned by
L<OptArgs2>.

=head2 inflate_optargs

  \%options = $form_meta->inflate( \%optargs );

Inflate the "flat" options hash returned by L<OptArgs2> into the full
hash required to initialize the form.

When the L<OptArgs2> option specification is generated from the form
structure via L</optargs>, the form structure is flattened into a one
dimensional hash.  The hash keys are generated from the hierarchical
keys and a mapping between the hash keys and the original hierarchy
is recorded.

This method restores the original structure.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-form-tiny-plugin-optargs2@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Form-Tiny-Plugin-OptArgs2>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-form-tiny-plugin-optargs2

and may be cloned from

  https://gitlab.com/djerius/cxc-form-tiny-plugin-optargs2.git

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
