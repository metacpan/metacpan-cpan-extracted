package App::findeps;

use strict;
use warnings;
use feature qw(state);

our $VERSION = "0.13";

use Carp qw(carp croak);
use ExtUtils::Installed;
use List::Util qw(first);

use Module::CoreList;
use Directory::Iterator;

our $Upgrade    = 0;
our $myLib      = 'lib';
our $toCpanfile = 0;
my $qr4ext  = qr/\w+\.(p[ml]|t|cgi|psgi)$/;
my $qr4name = qr/[a-zA-Z][a-zA-Z\d]+(?:::[a-zA-Z\d]+){0,}/;

sub scanDir {    # To Do
    my $dir = shift || $myLib || 'lib';
    die "$dir is not a directory" unless -d $dir;

    my @list = ();
    my $list = Directory::Iterator->new($dir);
    while ( $list->next ) {
        my $file = $list->get;
        next unless $file =~ /\.p[lm]$/;
        scan( file => $file, list => \@list );
    }
    return @list;
}

sub scan {
    my %args = @_;
    my %pairs;
    while ( my $file = shift @{ $args{files} } ) {
        ( my $ext = $file ) =~ $qr4ext;
        warn "Invalid extension was set: $ext" unless $1;
        open my $fh, '<', $file or die "Can't open < $file: $!";
        while (<$fh>) {
            chomp;
            next unless defined $_;
            last if /^__(?:END|DATA)__$/;
            state( $pod, $here, $eval );
            next if $pod  and $_ ne '=cut';
            next if $here and $_ ne $here;
            if ( !$pod and /^=(\w+)/ ) {
                $pod = $1;
                next;
            } elsif ( $pod and $_ eq '=cut' ) {
                undef $pod;
                next;
            }
            if ( !$here and my @catch = /(?:<<(['"])?(\w+)\1?){1,}/g ) {
                $here = $catch[-1];
                next;
            } elsif ( $here and $_ eq $here ) {
                undef $here;
                next;
            }
            next if /^\s*#.*/;
            s/\s+#.*$//;
            if ( !$eval and /eval\s*(['"{])$/ ) {
                $eval = $1 eq '{' ? '}' : $1;
            } elsif ( $eval and /$eval(?:.*)?;$/ ) {
                undef $eval;
                next;
            } elsif ( $eval and /\b(require|use)\s+($qr4name)/ ) {
                warnIgnored( $2, $1, 'eval' );
            }
            next if $eval;

            if (/\buse\b/) {
                scan_line( \%pairs, $_ );
                next;
            }

            state $if = 0;
            if (/^\b(?:if|unless)\s*\(.*\)\s*{$/) {
                $if++;
            } elsif ( $if > 0 and /^\s*}$/ ) {
                $if--;
                warn "something wrong to parse: $file" if $if < 0;
                next;
            } elsif ( $if > 0 and /^\brequire\s+($qr4name)/ ) {
                warnIgnored( 'require', $1, 'if' );
            }
            next unless /\b(require|use)\s+/;
            scan_line( \%pairs, $_ );
        }
        close $fh;
    }
    my $deps  = {};
    my @local = ();
    my $list  = Directory::Iterator->new($myLib)
        ;    # To Do: $myLib must be got from local::lib within plenv/PerlBrew
    while ( $list->next ) {
        my $file = $list->get;
        next unless $file =~ s!\.pm$!!;
        $file =~ s!/!::!g;
        push @local, $file;
    }

    while ( my ( $name, $version ) = each %pairs ) {
        next                      if !defined $name;
        next                      if exists $deps->{$name};
        next                      if first { $_ eq $name } @local;
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
    my @names = ();
    return if /^\buse\s+v5(?:\.\d{2}){1,2}\s*;/;    #ignore VERSION
    return if /^\buse\s+5\.\d{3}(?:_\d{3})?;/;      #ignore old version

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
        next unless defined $name;
        next if exists $pairs->{$name};
        next if $name eq 'Plack::Builder';
        next if first { $name eq $_ } @pragmas;
        next if !$Upgrade and Module::CoreList->is_core($name);
        $pairs->{$name} = get_version($name);
    }
    return %$pairs;
}

sub get_version {
    my $name      = shift;
    my $installed = ExtUtils::Installed->new( skip_cwd => 1 );
    my $module    = first { $_ eq $name } $installed->modules();
    my $version   = eval { $installed->version($module) };
    return $version if defined $version;
    eval "use lib '$myLib'; require $name" or return undef;
    return eval "no strict 'subs';\$${name}::VERSION";
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
    $str =~ s!\.pm$!!;
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
