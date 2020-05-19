# Data::Hopen::Util::Filename - functions for manipulating filenames
package Data::Hopen::Util::Filename;
use strict;
use Data::Hopen::Base;

our $VERSION = '0.000018';

use parent 'Exporter';
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw();
    @EXPORT_OK = qw(obj exe lib);
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );
}

use Class::Method::Modifiers qw(fresh);
use Config;
use Data::Hopen;

# Docs {{{1

=head1 NAME

Data::Hopen::Util::Filename - functions for manipulating filenames

=head1 SYNOPSIS

Nothing is exported by default.  Each function is available via an OO
interface or a procedural interface.

=head1 FUNCTIONS

=cut

# }}}1

=head2 obj

Return the given filename, with the extension of an object file added.
Usage:

    Data::Hopen::Util::Filename::obj(filename[, -strip=>true]);    # procedural
    Data::Hopen::Util::Filename->new->obj(fn[, -strip=>true]);     # OO

If C<< -strip => <truthy> >> is given, strip any existing extension first.

=head2 exe

Return the given filename, with the extension of an executable file added.
Usage and options are the same as L</obj>.

=head2 lib

Return the given filename, with the extension of a library file added.
Usage and options are the same as L</obj>.

=cut

# Create obj(), exe(), and lib() in a loop since they share the same skeleton.

BEGIN {
    foreach my $lrFunction ([qw(obj _o obj_ext .o)],
                            [qw(exe _exe exe_ext), ''],
                            [qw(lib _a lib_ext .a)])
    {
        fresh $lrFunction->[0] => sub {
            my (undef, %args) = getparameters(__PACKAGE__, [qw(filename; strip)], @_);
                # __PACKAGE__ => Permit OO interface
            $args{filename} =~ s/\.[^.]*$// if $args{strip};
            return $args{filename} .
                    ($Config{$lrFunction->[1]} // $Config{$lrFunction->[2]} //
                        $lrFunction->[3]);
        };
    }
}

=head2 new

Create a new instance for the OO interface.  For example:

    my $FN = Data::Hopen::Util::Filename->new;
    say $fn->obj('hello');      # e.g., "hello.o" or "hello.obj"

=cut

sub new { bless {}, shift }

1;
__END__
# vi: set fdm=marker: #
