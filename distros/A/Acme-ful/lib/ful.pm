use strict;
use warnings;

package ful;

=pod

=encoding utf-8

=head1 NAME

ful - a useI<ful> "B<f>ind B<u>pper B<l>ib" pragma that ascends dirs to include
module directories in C<@INC>.

=head1 SYNOPSIS

One line to rule them all.

    use ful;

Within C<a-script.pl> when your project looks like this:

    project-root/
    ├── bin/
    │   └── utils/
    │       └── a-script.pl
    ├── lib/
    ├── vendor/
    │   └── SomeOrg/
    │       └── Some/
    │           └── Module.pm

And that's it.

And if you need more than just the C<project-root/lib> dir, you can do this:

    use ful qw/vendor lib/;

Instead of:

    use lib::relative '../../lib';
    use lib::relative '../../vendor';
    # or
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use lib "$FindBin::Bin/../vendor";
    # or even
    BEGIN {
        use Path::Tiny;
        my $base = path(__FILE__)->parent;
        $base = $base->parent until -d "$base/lib" or $base->is_rootdir;
        unshift @INC, "$base/lib", "$base/vendor";
    }

=head1 LICENSE

MIT License

Copyright (c) 2020 Ryan Willis <code@ryanwillis.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 VERSION

0.07

=head1 SUPPORT

Support is by the author. Please file bug reports or ask questions at
L<https://github.com/ryan-willis/p5-Acme-ful/issues>.

=cut

our $VERSION = '0.07';

use Cwd;
use File::Spec;

my $cursor;

my $FS = 'File::Spec';

our $crum = undef;

sub import {
    my $me = shift;

    my @user    = caller();
    my $used_me = $user[1];

    $cursor = Cwd::abs_path($used_me);

    my %args    = ();
    my @libdirs = ('lib');

    if (@_ && ref($_[0]) eq 'HASH') {
        %args = %{$_[0]};
    }
    elsif(@_) {
        @libdirs = @_;
    }

    @libdirs = @{$args{libdirs}} if ref($args{libdirs}) eq 'ARRAY';

    if (my $file = $args{file} // $args{target_file} // $args{target}) {
        $me->_ascend until $me->_is_file($file) or $me->_heaven;
    }
    elsif (my $dir = $args{dir} // $args{has_dir} // $args{child_dir}) {
        $me->_ascend until $me->_is_dir($dir) or $me->_heaven;
    }
    elsif ($args{git}) {
        my @gitparts = qw(.git config);
        $me->_ascend until $me->_is_file(@gitparts) or $me->_heaven;
    }
    else {
        while (!$me->_heaven) {
            last if scalar @libdirs == grep { $me->_is_dir($_) } @libdirs;
            $me->_ascend;
        }
    }

    return if $me->_heaven;
    $crum = $me->_comb($cursor);
    unshift @INC => $me->_comb($cursor, $_) for @libdirs;
}

sub _is_file { -f shift->_comb($cursor, @_) }
sub _is_dir  { -d shift->_comb($cursor, @_) }
sub _comb    { $FS->catfile(@_[1..$#_])     }

sub _ascend  { $cursor = $FS->catdir(($FS->splitpath($cursor))[0..1]) }
sub _heaven  { $cursor eq $FS->rootdir }

1;

__END__