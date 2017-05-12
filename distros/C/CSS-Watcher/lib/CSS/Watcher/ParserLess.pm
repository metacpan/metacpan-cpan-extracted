package CSS::Watcher::ParserLess;

use warnings;
use strict;

use Path::Tiny;
use File::Which;
use IPC::Run3;
use Log::Log4perl qw(:easy);

use CSS::Watcher::Parser;

sub new {
    my $class = shift;

    return bless ({}, $class);
}

sub parse_less {
    my $self = shift;
    my $filename = shift;

    my $cmd = [ $self->executable,
                '--no-color',
                $filename
            ];
    my $err;
    my $out;
    local ($!, $?) = (0, -1);
    IPC::Run3::run3($cmd, undef, \$out, \$err, {return_if_system_error => 1});

    if (!$?) {
       $err = '';
    } elsif ($! == 2) {
        ERROR sprintf "Cannot execute '%s'. See http://lesscss.org/#usage", $cmd->[0];
    } else {
        DEBUG sprintf "Failed to run \"%s\":\n  %s\n%s", join(' ', @$cmd), $err, $out;
        $out = '';
    }

    my ($classes, $ids) = ({}, {});
    if ($out ne '') {
        INFO sprintf '%s: lessc done, parsing generated CSS', path($filename)->basename;
        ($classes, $ids) = CSS::Watcher::Parser->new->parse_css($out);
    }

    # Find dependencies for this less file.
    my @requiries;
    foreach (path($filename)->lines_utf8()) {
        (m/^\s*?\@import\s+"(.*?.less)"/) ? push @requiries, $1 :
        (m/^\s*?\@import\s+"(.*?.css)"/)  ? push @requiries, $1 :
        (m/^\s*?\@import\s+"(.*?)"/)  ? push @requiries, $1 . '.less' : 1;
    }

    INFO sprintf "%s: imports: %s", path($filename)->basename, join(', ', @requiries)  if (@requiries);

    return ($classes, $ids, \@requiries);
}

sub executable {
    File::Which::which('lessc') || 'lessc' ;
}

1;

__END__

=head1 NAME

CSS::Watcher::ParserLess - Extract classes, ids from .less files

=head1 SYNOPSIS

   use CSS::Watcher::ParserLess;
   my $parser = CSS::Watcher::Parser->new()

   # return requiries - ref array of dependencies
   my ($hclasses, $hids, $requiries) = parser->parse_less (<<LESS)
   @import "foo.less"
   LESS
   ;
   # $requiries = ["foo.less"]

=head1 DESCRIPTION

Use lessc for compile less and parse css result by CSS::Watcher::Parser.

=head1 AUTHOR

Olexandr Sydorchuk (olexandr.syd@gmail.com)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Olexandr Sydorchuk

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
