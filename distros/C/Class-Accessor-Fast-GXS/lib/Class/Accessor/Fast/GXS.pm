=head1 NAME

Class::Accessor::Fast::GXS - generate C::A::Fast compatible XS accessors

=head1 DESCRIPTION

This module allows you to generate a XS code for accessors you need
your classes. It's implemented on top of Class::Accessor::Fast and
fallbacks to it when it's not possible to access C library.

This code is quite experimental and API for generating XS is not
settled down. It's up to you to try and suggest the way you want
generator to work.

=head1 USAGE

Setup inheritance from Class::Accessor::Fast::GXS

The top of a Makefile.PL

    BEGIN {
        use Class::Accessor::Fast::GXS;
        local $Class::Accessor::Fast::XS::GENERATE_TO = "TAccessors.xs";
        local $Class::Accessor::Fast::XS::MODULE = "My::TAccessors";
        require "lib/My/TAccessors.pm";
    };

    use inc::Module::Install;
    ...

It generates TAccessors.xs from mk*accessor calls in your modules.

See also example dir in the tarball.

=head1 REQUEST FOR IDEAS

There are some things that must be considered before running this in
production:

=over 4

=item Installation

L<Module::Install> system installs your module into arch specific
dirs when it has XS code, I don't think it the right way. I think
your module should be installed in the old way except for binary
parts.

=item Generation

The current API for generation is kind cryptic still and subject
to change.

=item Compilation

I think that your modules should still be installable when people
have no compiler.

=item CPU cache

The module may gen a lot of subs in one object file and I have no
enough C-fu to say what is the best way to re-organize the code to
make object file smaller, CPU cache effective and don't loose
overall performance.

=back

=head1 PERFORMANCE

Here is comparings:

                       Rate       get_caf get_dummy_sub    get_cafgxs  get_dummy_ha
    get_caf        767999/s            --          -26%          -62%          -80%
    get_dummy_sub 1037900/s           35%            --          -49%          -73%
    get_cafgxs    2016491/s          163%           94%            --          -48%
    get_dummy_ha  3855058/s          402%          271%           91%            --
                           Rate set_one_caf set_one_dummy_sub set_one_cafgxs set_one_dummy_ha
    set_one_caf        568700/s          --              -35%           -72%             -83%
    set_one_dummy_sub  877713/s         54%                --           -57%             -74%
    set_one_cafgxs    2029875/s        257%              131%             --             -39%
    set_one_dummy_ha  3317254/s        483%              278%            63%               --
                             Rate set_multi_caf set_multi_dummy_sub set_multi_cafgxs set_multi_dummy_ha
    set_multi_caf        548746/s            --                 -4%             -74%               -84%
    set_multi_dummy_sub  573439/s            4%                  --             -73%               -83%
    set_multi_cafgxs    2117316/s          286%                269%               --               -38%
    set_multi_dummy_ha  3389792/s          518%                491%              60%                 --
                      Rate       mix_caf mix_dummy_sub    mix_cafgxs  mix_dummy_ha
    mix_caf       195491/s            --          -10%          -68%          -80%
    mix_dummy_sub 216392/s           11%            --          -65%          -78%
    mix_cafgxs    613304/s          214%          183%            --          -39%
    mix_dummy_ha  998734/s          411%          362%           63%            --


Where "caf" is L<Class::Accessor::Fast>, "cafgxs" is generated, "dummy_sub" is a perl sub that do
just what we need and nothing else and "dummy_ha" is just dirrect hash access.

See also example dir in the tarball.

=cut

package Class::Accessor::Fast::GXS;

use 5.8.0;
use strict;
use warnings;

use base qw(Class::Accessor::Fast);

our $VERSION = '0.01';

our $GENERATE_TO = undef;
our $MODULE = undef;
our $DEBUG = 0;

my $head = <<END;
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
END

my %failed_loads = ();
sub __xs_load_or_fallback_to_super {
    my $self = shift;
    my $method = 'SUPER::'. shift;
    my $field = shift;
    my $name = shift;
    my $class = ref $self || $self;

    no strict 'refs';

    return \&{"${class}::__xs_$name"}
        if defined &{"${class}::__xs_$name"};

    my @parts = split /::/, $class;
    my $found = 0;
    do {
        local $@;
        my $module = join "::", @parts;
        if ( $failed_loads{$module} || !eval { require XSLoader; XSLoader::load($module); 1 } ) {
            $failed_loads{$module} = 1;
        } else {
            $found = 1;
        }
        pop @parts;
    } while @parts;
    unless ( $found ) {
        warn "not found dynamic library for $class" if $DEBUG;
        return $self->$method($field, @_);
    }

    return \&{"${class}::__xs_$name"}
        if defined &{"${class}::__xs_$name"};

    warn "C lib has no $name in $class" if $DEBUG;
    return $self->$method($field, @_);
}

my %handles = ();
sub __get_handle_for_xs {
    my $self = shift;
    my $class = ref $self || $self;
    my $module = $MODULE || $class;

    my $fh = $handles{ $module };
    return $fh if $fh;

    my $fn = $GENERATE_TO;
    $fn = join '/', $GENERATE_TO, split /::/, $module .".xs"
        if -d $GENERATE_TO;

    open $fh, ">", $fn or die "couldn't open file '$fn': $!";
    $handles{ $module } = $fh;

    print $fh $head, "\n\n";

    return $fh;
}

# XXX: escaping and unicode support
my %done = ();

sub make_ro_accessor {
    my $self = shift;
    my $field = shift;
    my $name = $self->accessor_name_for($field);
    return $self->__xs_load_or_fallback_to_super('make_ro_accessor', $name, $field, @_)
        unless defined $GENERATE_TO;

    my $class = ref $self || $self;
    return if $done{$class."::".$name}++;

    warn "making $field ro accessor for $class" if $DEBUG;

    my $fh = $self->__get_handle_for_xs;
    print $fh "MODULE = ". ($MODULE||$class) ." PACKAGE = $class\n\n";

    my $length = length $field;
    print $fh <<END;
void
__xs_$name(self)
    SV* self;
  PROTOTYPE: DISABLE
  INIT:
    SV** res;
  PPCODE:
    res = hv_fetch((HV *)SvRV(self), "$field", $length, 0);
    if (res == NULL)
        XSRETURN_UNDEF;

    XPUSHs(*res);

END

    return undef;
}

sub make_wo_accessor {
    my $self = shift;
    my $field = shift;
    my $name = $self->mutator_name_for($field);
    return $self->__xs_load_or_fallback_to_super('make_wo_accessor', $name, $field, @_)
        unless defined $GENERATE_TO;

    my $class = ref $self || $self;
    return if $done{$class."::".$name}++;

    warn "making $field wo accessor for $class" if $DEBUG;

    my $fh = $self->__get_handle_for_xs;
    print $fh "MODULE = ". ($MODULE||$class) ." PACKAGE = $class\n\n";

    my $length = length $field;
    print $fh <<END;
void
__xs_$name(self, ...)
    SV* self;
  PROTOTYPE: DISABLE
  INIT:
    SV **res;
    SV *newvalue;
    IV i;
  PPCODE:
    if ( items == 2 ) {
        newvalue = SvREFCNT_inc(ST(1));
    } else if ( items > 2 ) {
        AV* tmp = newAV();
        av_extend(tmp, items-1);
        for(i = 1; i < items; i++) {
            if (!av_store(tmp, i - 1, SvREFCNT_inc(ST(i)))) {
                SvREFCNT_dec(ST(i));
                croak("Cannot store value in array");
            }
        }
        newvalue = newRV_noinc((SV*) tmp);
    } else {
        croak("Cannot access the value");
    }

    if (res = hv_store((HV*)SvRV(self), "$field", $length, newvalue, 0)) {
        XPUSHs(*res);
    } else {
        SvREFCNT_dec(newvalue);
        croak("Failed to write new value to hash.");
        XSRETURN_UNDEF;
    }

END

    return undef;
}

sub make_accessor {
    my $self = shift;
    my $field = shift;
    # doesn't matter here what to call, they are equal
    my $name = $self->mutator_name_for($field);
    return $self->__xs_load_or_fallback_to_super('make_accessor', $name, $field, @_)
        unless defined $GENERATE_TO;

    my $class = ref $self || $self;
    return if $done{$class."::".$name}++;

    warn "making $field accessor for $class" if $DEBUG;

    my $fh = $self->__get_handle_for_xs;
    print $fh "MODULE = ". ($MODULE||$class) ." PACKAGE = $class\n\n";

    my $length = length $field;
    print $fh <<END;
void
__xs_$name(self, ...)
    SV* self;
  PROTOTYPE: DISABLE
  INIT:
    SV **res;
    SV *newvalue;
    IV i;
  PPCODE:
    if ( items == 1 ) {
        res = hv_fetch((HV *)SvRV(self), "$field", $length, 0);
        if (res == NULL)
            XSRETURN_UNDEF;

        XPUSHs(*res);
        XSRETURN(1);
    }
    else if ( items == 2 ) {
        newvalue = SvREFCNT_inc(ST(1));
    }
    else {
        AV* tmp = newAV();
        av_extend(tmp, items-1);
        for(i = 1; i < items; i++) {
            if (!av_store(tmp, i - 1, SvREFCNT_inc(ST(i)))) {
                SvREFCNT_dec(ST(i));
                croak("Cannot store value in array");
            }
        }
        newvalue = newRV_noinc((SV*) tmp);
    }

    if (res = hv_store((HV*)SvRV(self), "$field", $length, newvalue, 0)) {
        XPUSHs(*res);
    } else {
        SvREFCNT_dec(newvalue);
        croak("Failed to write new value to hash.");
        XSRETURN_UNDEF;
    }

END

    return undef;
}

1;

__END__

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
