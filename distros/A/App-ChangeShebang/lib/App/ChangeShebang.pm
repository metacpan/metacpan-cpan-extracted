package App::ChangeShebang;
use strict;
use warnings;
use utf8;
use Getopt::Long qw(:config no_auto_abbrev no_ignore_case bundling);
use Pod::Usage 'pod2usage';
require ExtUtils::MakeMaker;
use File::Basename 'dirname';
use File::Temp 'tempfile';
sub prompt { ExtUtils::MakeMaker::prompt(@_) }

our $VERSION = '0.07';

sub new {
    my $class = shift;
    bless {@_}, $class;
}
sub parse_options {
    my $self = shift;
    local @ARGV = @_;
    GetOptions
        "version|v" => sub { printf "%s %s\n", __PACKAGE__, $VERSION; exit },
        "quiet|q"   => \$self->{quiet},
        "force|f"   => \$self->{force},
        "help|h"    => sub { pod2usage(0) },
    or pod2usage(1);

    my @file = @ARGV;
    unless (@file) {
        warn "Missing file arguments.\n";
        pod2usage(1);
    }
    $self->{file} = \@file;
    $self;
}

sub run {
    my $self = shift;
    for my $file (@{ $self->{file} }) {
        next unless -f $file && !-l $file;
        next unless $self->is_perl_shebang( $file );
        unless ($self->{force}) {
            my $anser = prompt "change shebang line of $file? (y/N)", "N";
            next if $anser !~ /^y(es)?$/i;
        }
        $self->change_shebang($file);
        warn "changed shebang line of $file\n" unless $self->{quiet};
    }
}

sub is_perl_shebang {
    my ($self, $file) = @_;
    open my $fh, "<:raw", $file or die "open $file: $!\n";
    read $fh, my $first, 100 or die "read $file: $!\n";
    return $first =~ /^#!([^\n]*)perl/ ? 1 : 0;
}

my $remove = do {
    my $s = qr/[ \t]*/;
    my $w = qr/[^\n]*/;
    my $running_under_some_shell = qr/\n*
        $s eval $s ['"] exec $w \n
            $s if $s (?:0|\$running_under_some_shell) $w \n
    /xsm;
    my $shebang = qr/\n*
        \#! $w \n
    /xsm;
    qr/\A(?:$running_under_some_shell|$shebang)+/;
};

sub change_shebang {
    my ($self, $file) = @_;
    my $content = do {
        open my $fh, "<:raw", $file or die "open $file: $!\n";
        local $/; <$fh>;
    };

    $content =~ s/$remove//;

    my $mode = (stat $file)[2];

    my ($tmp_fh, $tmp_name) = tempfile UNLINK => 0, DIR => dirname($file);
    chmod $mode, $tmp_name;
    print {$tmp_fh} <<'...';
#!/bin/sh
exec "$(dirname "$0")"/perl -x "$0" "$@"
#!perl
...
    print {$tmp_fh} $content;
    close $tmp_fh;
    rename $tmp_name, $file or die "rename $tmp_name, $file: $!\n";
}


1;
__END__

=encoding utf-8

=head1 NAME

App::ChangeShebang - change shebang lines for relocatable perl

=head1 SYNOPSIS

    > change-shebang /path/to/bin/script.pl

    > head -3 /path/to/bin/script.pl
    #!/bin/sh
    exec "$(dirname "$0")"/perl -x "$0" "$@"
    #!perl

=head1 DESCRIPTION

L<change-shebang> changes shebang lines from

    #!/path/to/bin/perl

to

    #!/bin/sh
    exec "$(dirname "$0")"/perl -x "$0" "$@"
    #!perl

Why do we need this?

Let's say you build perl with relocatable enabled (C<-Duserelocatableinc>).
Then the shebang lines of executable scripts point at
the installation time perl binary path.

So if you move your perl directory to other places,
the shebang lines of executable scripts point at a wrong perl binary and
we cannot execute scripts. Oops!

A solution of that problem is to replace shebang lines by

    #!/bin/sh
    exec "$(dirname "$0")"/perl -x "$0" "$@"
    #!perl

which means that scripts will be executed by the perl located in the same directory.

=head1 SEE ALSO

=over 4

=item L<Relocatable installations in perl5100delta.pod|https://metacpan.org/pod/distribution/perl/pod/perl5100delta.pod#Relocatable-installations>

=item L<https://github.com/shoichikaji/relocatable-perl>

=item L<https://github.com/shoichikaji/relocatable-perl-growthforecast>

=back

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

