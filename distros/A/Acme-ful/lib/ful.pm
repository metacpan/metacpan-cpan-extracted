use strict;
use warnings;

package ful;

=pod

=encoding utf-8

=head1 NAME

ful - a useI<ful> "B<f>ind B<u>pper B<l>ib" pragma that ascends dirs to include
module directories in C<@INC>.

=head1 SYNOPSIS

=begin HTML

<span>
    <a href="https://badge.fury.io/pl/Acme-ful">
        <img src="https://badge.fury.io/pl/Acme-ful.svg" alt="CPAN Current Version" height="18">
    </a>
    <a href="https://cpants.cpanauthors.org/release/RWILLIS/Acme-ful-0.11">
        <img src="https://cpants.cpanauthors.org/release/RWILLIS/Acme-ful-0.11.svg" alt="CPAN Module Quality" />
    </a>
    <a href="https://travis-ci.org/github/ryan-willis/ful.pm">
        <img src="https://travis-ci.org/ryan-willis/ful.pm.svg?branch=master" alt="Build Status" />
    </a>
    <a href="https://coveralls.io/github/ryan-willis/ful.pm?branch=master">
        <img src="https://coveralls.io/repos/github/ryan-willis/ful.pm/badge.svg?branch=master" alt="Coverage Status" />
    </a>
</span>

=end HTML

One line to rule them all.

    use ful;

Brings the first C<lib/> directory found by directory ascencion and adds it to
C<@INC>.

Instead of:

    use lib::relative '../../lib';
    # or
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    # or even
    BEGIN {
        use Path::Tiny;
        my $base = path(__FILE__)->parent;
        $base = $base->parent until -d "$base/lib" or $base->is_rootdir;
        unshift @INC, "$base/lib";
    }

=head1 USAGE

When you're working within C<a-script.pl> when your project looks like this:

    project-root/
    ├── bin/
    │   └── utils/
    │       └── a-script.pl
    ├── lib/
    │   └── Some/
    │       └── Module.pm
    ├── vendor/
    │   └── SomeOrg/
    │       └── Some/
    │           └── Module.pm

Just drop the line before your other C<use> statements:

    use ful;
    use Some::Module;

And that's all.

If you need more than just the C<project-root/lib> dir, you can do this:

    use ful qw/vendor lib/;
    use Some::Module;
    use SomeOrg::Some::Module;

=head1 METHODS

=over 4

=item * crum()

Returns the parent directory for the latest addition to C<@INC>.

=back

=head1 ADVANCED

    use ful \%options;

=head2 OPTIONS

=over 4

=item * C<libdirs =E<gt> \@dirs>

Equivalent to C<use ful qw/lib vendor/;> but can be combined with all other
options.

    # multiple @INC dirs
    use ful { libdirs => [qw/lib vendor/] };

    # combined with another option
    use ful {
        libdirs => [qw(lib vendor/lib)],
        dir     => 'vendor/lib',
    };

=item * C<file =E<gt> $file>, C<target_file =E<gt> $file>, C<target =E<gt> $file>

Finds an existing file to add a sibling directory to C<@INC>.

    # adds 'lib'
    use ful { file => '.file-in-project-root' };

=item * C<dir =E<gt> $dname>, C<has_dir =E<gt> $dname>, C<child_dir =E<gt> $dname>

Finds an existing directory to add a sibling directory to C<@INC>.

    # adds 'lib'
    use ful { dir => 'bin' };

=item * C<git =E<gt> 1>

Finds a git repository to add a sibling directory to C<@INC>.

    # adds 'lib'
    use ful { git => 1 };

=back

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

0.11

=head1 SUPPORT

Support is by the author. Please file bug reports or ask questions at
L<https://github.com/ryan-willis/ful.pm/issues>.

=cut

our $VERSION = '0.11';

use Cwd;
use File::Spec;

my $cursor;

my $FS = 'File::Spec';

our $crum = undef;

sub crum { $crum }

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