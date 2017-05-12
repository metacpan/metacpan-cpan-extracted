package Any::Moose::Convert;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.004';

use base qw(Exporter);
our @EXPORT = qw(moose2mouse mouse2moose);

use PerlIO::Util;
use File::Find;
use File::Spec;
use File::Path qw(mkpath);
use File::Basename qw(dirname);

my $IGNORE = qr/\A \. (?: git | svn | cvs | hg) \b/;

sub moose2mouse { _moose2mouse(1, @_) }
sub mouse2moose { _moose2mouse(0, @_) }

sub _moose2mouse {
    my $moose2mouse = shift;

    my @paths = @_ ? @_ : @ARGV;

    my $dry_run;
    $dry_run = !!(shift @paths) if $paths[0] eq '--dry-run';

    foreach my $file(_expand(@paths)){
        my $new_file = $file;

        if($moose2mouse){
            $new_file =~ s/Moose/Mouse/g;
        }
        else{
            $new_file =~ s/Mouse/Moose/g;
        }

        if($new_file !~ /^mo[ou]se/){
            $new_file = File::Spec->catfile(
                $moose2mouse ? 'mouse' : 'moose',
                $new_file
            );
        }

        print "$file to $new_file\n";

        next if $dry_run;

        _do_moose2mouse_to_file($moose2mouse, $file, $new_file);
    }
    return;
}

sub _expand {
    my @files;
    foreach my $path(@_){
        if(-e $path){
            if(-f $path){
                push @files, $path;
            }
            else{
                find(sub{
                    return if !-f $_;
                    push @files, $File::Find::name;
                }, $path);
            }
        }
        else{
            die "The path not found: $path\n";
        }
    }
    my %seen;

    return grep { !$seen{$_}++ }
        map{ File::Spec->abs2rel($_) } @files;
}

sub _do_moose2mouse_to_file {
    my($moose2mouse, $file, $new_file) = @_;

    my $content;
    {
        my $in = PerlIO::Util->open('<:raw', $file);
        local $/;
        $content = <$in>;
    }

    if($file !~ $IGNORE){
        if($moose2mouse){
            _convert_moose_to_mouse(\$content);
        }
        else{
            _convert_mouse_to_moose(\$content);
        }
    }

    mkpath(dirname($new_file), 1);

    my $out = PerlIO::Util->open('>:raw', $new_file);

    print $out $content;
    close $out or die "Cannot close '$new_file': $!\n";
    return;
}

my $cmop_utils = join '|', qw(
    is_class_loaded
    load_class
    load_first_existing_class
    class_of
    get_metaclass_by_name
    get_code_info
);

sub _convert_moose_to_mouse {
    local(*_) = @_;

    s{Moose}{Mouse}mxsg;

    # e.g. Class::MOP::load_class -> Mouse::Util::load_class
    s{\b Class::MOP::($cmop_utils) \b}
     {Mouse::Util::$1}mxsgo;

    s{\b use \s+ Class::MOP \b}
     {use Mouse::Meta::Class}xmsg;

    # e.g. Class::MOP::Class -> Mouse::Meta::Class
    s{\b Class::MOP:: \b}
     {Mouse::Meta::}xmsg;

    return;
}

sub _convert_mouse_to_moose {
    local(*_) = @_;

    s{\b Mouse::Util::($cmop_utils) \b}
     {Class::MOP::$1}mxsgo;

    s{Mouse}{Moose}mxsg;

    return;
}

1;
__END__

=head1 NAME

Any::Moose::Convert - Convert Moose libraries to Mouse ones, or vice versa

=head1 VERSION

This document describes Any::Moose::Convert version 0.004.

=head1 SYNOPSIS

	use Any::Moose::Convert;

	moose2mouse qw(lib); # makes moose/lib/...
	mouse2mouse qw(lib); # makes mouse/lib/...

	# or as a command

	$ perl -MAny::Moose::Convert -e 'moose2mouse lib'
	$ perl -MAny::Moose::Convert -e 'mouse2moose lib'


=head1 DESCRIPTION

Any::Moose::Convert is a tool to convert Moose libraries to Mouse ones, or vice versa.

=head1 INTERFACE

=head2 EXPORTED FUNCTIONS

=head3 moose2mouse(@paths = @ARGV)

=head3 mouse2moose(@paths = @ARGV)

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 SEE ALSO

L<Moose>

L<Mouse>

L<Any::Moose>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
