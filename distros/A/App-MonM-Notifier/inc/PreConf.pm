package PreConf; # $Id: SkelModule.pm 200 2017-05-01 08:51:48Z minus $
use strict;

=head1 NAME

PreConf - Configuration your modules on phase Preamble.

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    perl -Iinc -MPreConf -e dircp -- SRCDIR DSTDIR

    perl -Iinc -MPreConf -e crlfnorm -- DIR_OR_FILE_NAMES

=head1 DESCRIPTION

PreConf is a perl module that runs pre configuration tasks on phase Preamble.

B<FOR INTERNAL USE ONLY!>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) http://www.serzik.com <minus@serzik.com>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use base qw/Exporter/;
our @EXPORT = qw/dircp crlfnorm/;

use vars qw/$VERSION/;
$VERSION = '1.01';

use CTK qw/ say /;
use CTK::Util qw/ :BASE /;
use File::Copy qw/copy cp/;
use File::Copy::Recursive qw/dircopy/;
use File::Find;

sub dircp {
    _expand_wildcards();
    my @src = @ARGV;
    my $dst = pop @src;
    croak("Too many arguments") if (@src > 1 && ! -d $dst);

    my $nok = 0;
    foreach my $src (@src) {
        if (-f $src) {
            $nok ||= !cp($src, $dst);
        } elsif (-d $src) {
            $nok ||= !dircopy($src, $dst);
        } else { # Skipped
            say "Skip $src. This is not file and not directory";
        }
    }
    return $nok;
}
sub crlfnorm {
    find({ wanted => sub {
        return if -d;
        return unless -w _;
        return unless -r _;
        return if -B _;
        printf("Normalizing the linefeeds in file %s... ", catfile($File::Find::dir, $_));
        file_lf_normalize($_);
        print "Done.\n";
    }}, @ARGV);
    return 1;
}

sub _expand_wildcards {
    # Original in package ExtUtils::Command
    @ARGV = map(/[*?]/o ? glob($_) : $_, @ARGV);
}

1;
__END__
