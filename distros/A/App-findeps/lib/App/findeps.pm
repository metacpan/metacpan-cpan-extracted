package App::findeps;

use 5.012005;
use strict;
use warnings;

our $VERSION = "0.11";

use Carp qw(carp croak);
use ExtUtils::Installed;
use List::Util qw(first);
use FastGlob qw(glob);
use Module::CoreList;

our $Upgrade    = 0;
our $myLib      = 'lib';
our $toCpanfile = 0;
my $RE      = qr/\w+\.((?i:p[ml]|t|cgi|psgi))$/;
my $qr4name = qr/[a-zA-Z][a-zA-Z\d]+(?:::[a-zA-Z\d]+){0,}/;

sub scan {
    my %args = @_;
    my %pairs;
    while ( my $file = shift @{ $args{files} } ) {
        $file =~ $RE;
        my $ext = $1 || croak 'Unvalid extension was set';
        open my $fh, '<', $file or die "Can't open < $file: $!";
        while (<$fh>) {
            chomp;
            next unless length $_;
            last if /^__(?:END|DATA)__$/;
            next if /^\s*#.*$/;
            state( $pod, $here, $eval );
            if ( !$pod and /^=(\w+)/ ) {
                $pod = $1;
            } elsif ( $pod and /^=cut$/ ) {
                undef $pod;
                next;
            }
            if ( !$here and my @catch = /(?:<<(['"])?(\w+)\1?){1,}/g ) {
                $here = $catch[-1];
            } elsif ( $here and /^$here$/ ) {
                undef $here;
                next;
            }
            s/\s+#.*$//g;
            if ( !$eval and /eval\s*(['"{])$/ ) {
                $eval = $1 eq '{' ? '}' : $1;
            } elsif ( $eval and /$eval(?:.*)?;$/ ) {
                undef $eval;
                next;
            } elsif ( $eval and /(require|use)\s+($qr4name)/ ) {
                warnIgnored( $2, $1, 'eval' );
            }
            state $if = 0;
            if (/^\s*(?:if|unless)\s*\(.*\)\s*{$/) {
                $if++;
            } elsif ( $if > 0 and /^\s*}$/ ) {
                $if--;
                next;
            } elsif ( $if > 0 and /^\s*(require|use)\s+($qr4name)/ ) {
                warnIgnored( $2, $1, 'if' );
            }
            next if $pod or $here or $eval or $if;
            scan_line( \%pairs, $_ );
        }
        close $fh;
    }
    my $deps  = {};
    my @local = &glob("$myLib/*.p[lm]");
    while ( my ( $name, $version ) = each %pairs ) {
        next                      if !defined $name;
        next                      if exists $deps->{$name};
        next                      if first { $_ =~ /$name\.p[lm]$/ } @local;
        $deps->{$name} = $version if !defined $version or $Upgrade or $toCpanfile;
    }
    return $deps;
}

# subroutines #----#----#----#----#----#----#----#----#----#----#----#----#
my @pragmas = qw(
    attributes autodie autouse
    base bigint bignum bigrat blib bytes
    charnames constant diagnostics encoding
    feature fields filetest if integer less lib locale mro
    open ops overload overloading parent re
    sigtrap sort strict subs
    threads threads::shared utf8 vars vmsish
    warnings warnings::register
);

sub scan_line {
    my $pairs = shift;
    local $_ = shift;
    s/#.*$//;
    my @names = ();
    return if /^\s*(?:require|use)\s+5\.\d{3}_?\d{3};$/;
    if (/use\s+(?:base|parent)\s+qw[\("']\s*((?:$qr4name\s*){1,})[\)"']/) {
        push @names, split /\s+/, $1;
    } elsif (/use\s+(?:base|parent|autouse)\s+(['"])?($qr4name)\1?/) {
        $names[0] = $2;
    } elsif (/eval\s*(['"{])\s*(require|use)\s+($qr4name).*(?:\1|})/) {
        warnIgnored( $3, $2, 'eval' );
    } elsif ( /(?:if|unless)\s+\(.*\)\s*\{.*require\s+($qr4name).*\}/
        or /require\s+($qr4name)\s+(?:if|unless)\s+\(?.*\)?/ )
    {
        warnIgnored( $1, 'require', 'if' );
    } elsif (/^\s*(?:require|use)\s+($qr4name)/) {
        $names[0] = $1;

    } elsif (m!^\s*require\s*(["'])((?:\./)?(?:\w+/){0,}$qr4name\.pm)\1!) {
        $names[0] = _name($2);
    } elsif (/^\s*(require|use)\s+(['"]?)(.*)\2/) {
        my $name   = $3;
        my $exists = ( -e "$myLib/$name" ) ? 'exists' : "does not exist in $myLib";
        warn "just detected but not listed: $name($exists) $1d\n";
    }
    for my $name (@names) {
        next unless length $name;
        next if exists $pairs->{$name};
        next if $name eq 'Plack::Builder';
        next if $Upgrade and Module::CoreList->is_core($name);
        next if first { $name eq $_ } @pragmas;
        $pairs->{$name} = get_version($name);
    }
    return %$pairs;
}

sub get_version {
    my $name      = shift;
    my $installed = ExtUtils::Installed->new( skip_cwd => 1 );
    my $module    = first { $_ eq $name } $installed->modules();
    my $version   = eval { $installed->version($module) };
    return "$version" if $version;
    eval "use lib '$myLib'; require $name" or return undef;
    return eval "no strict 'subs';\$${name}::VERSION" || 0;
}

sub warnIgnored {
    my $name = shift;
    my $func = shift;
    my $cmd  = shift;
    warn "$name is ${func}d inside of '$cmd'\n" unless Module::CoreList->is_core($name);
}

sub _name {
    my $str = shift;
    $str =~ s!/!::!g if $str =~ /\.pm$/;
    $str =~ s!^lib::!!;
    $str =~ s!.pm$!!i;
    $str =~ s!^auto::(.+)::.*!$1!;
    return $str;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::findeps - the Module to find dependencies for files you've selected

=head1 SYNOPSIS

Via the command-line program L<findeps>;

    $ findeps Plack.psgi | cpanm
    $ findeps index.cgi | cpanm
    $ findeps t/00_compile.t | cpanm

=head1 DESCRIPTION

App::findeps is a base module for executing L<findeps>

=head1 TODO

is moved to L<github issue|https://github.com/worthmine/App-findeps/issues>

=head1 SEE ALSO

L<findeps>

=head1 LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida(L<worthmine|https://github.com/worthmine>)

=cut
