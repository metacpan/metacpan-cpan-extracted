# $Id: Makefile.PL,v 1.5 2002/02/16 18:27:22 btrott Exp $

use ExtUtils::MakeMaker qw( prompt WriteMakefile );
use strict;

my %PREREQS = (
    _base => {
        'Digest::MD5'       => 0,
        'Math::Pari'        => '2.001804',
        'Data::Buffer'      => 0,
        'MIME::Base64'      => 0,
    },

    PEM   => {
        'Convert::PEM'      => '0.05',
        'Crypt::DES'        => 0,
    },

    SSH   => {
        'Crypt::CBC'        => '2.00',
        'Crypt::DES'        => 0,
    },
);

my %all;
for my $type (keys %PREREQS) {
    for my $mod (keys %{ $PREREQS{$type} }) {
        $all{$mod} = $PREREQS{$type}{$mod};
    }
}
$PREREQS{_all} = \%all;

my %prereq = %{ $PREREQS{_base} };

print<<MSG;
This is Crypt::Keys.

Crypt::Keys contains read/write routines for a variety of
public and private key algorithms; each algorithm can be
encoded in several different formats. For example, you might
have a private RSA key file, encoded in PEM format.

In order to determine the modules you'll need on your system,
you must select the types of encoding you will be using. Please
choose the encodings you'd like to use from the following list
("All" is the default).

MSG

my($i, @map) = (0);
for my $enc (keys %PREREQS) {
    next if $enc =~ /^_/;
    $map[++$i] = $enc;
    printf "    [%d] %s\n", $i, $enc;
}
$i++;
printf "    [$i] All\n";

my $p = prompt("\nEnter your choices for encoding(s), separated by spaces:", $i);
print "\n";

if ($p == $i) {
    $p = join ' ', 1..$i-1;
}

for my $id (split /\s+/, $p) {
    next if $id == $i;
    for my $mod (keys %{ $PREREQS{$map[$id]} }) {
        $prereq{$mod} = $PREREQS{$map[$id]}{$mod};
    }
}

print "\nChecking for required modules\n\n";
my(%todo, $missing);
while (my($k, $v) = each %prereq) {
    unless (check_module($k, $v, \$missing)) {
        $todo{$k} = $v;
    }
}

use Cwd;
my $cwd = cwd();

if (%todo) {
    print <<MSG;
Crypt::Keys depends on several external modules for functionality.
Some of these modules can not be found on your system; they can be
installed automatically for you. To do so will require loading the
CPAN shell, which may require you to be running as root. Answer 'n' to
each of the following questions if you'd rather not install any
needed modules right now; note, however, that you'll still need to
install them to use Crypt::Keys.

MSG

    while (my($k, $v) = each %todo) {
        if (prompt(sprintf("%s%s not installed/out of date. Install (y/n)?",
          $k, $v ? " (ver. $v)" : ""), "y") =~ /^y/) {
            require CPAN; CPAN::Shell->install($k);
            delete $prereq{$k};
            chdir $cwd or die "Can't chdir back to $cwd: $!";
        }
    }
}

=pod

print "\nChecking for optional modules\n\n";

unless (check_module('Digest::BubbleBabble', 0.01, \$missing)) {
    print<<MSG, "\n";
Digest::BubbleBabble is required if you want to generate bubble babble
key fingerprints.
MSG
    if (read_yes_or_no("Would you like to install it now? (y/n)", "y")) {
        require CPAN; CPAN::Shell->install('Digest::BubbleBabble');
        chdir $cwd or die "Can't chdir back to $cwd: $!";
    }
    print "\n";
}

=cut

print "\n";
WriteMakefile(
    NAME => 'Crypt::Keys',
    DISTNAME => 'Crypt-Keys',
    VERSION_FROM => 'lib/Crypt/Keys.pm',
    PREREQ_PM    => \%prereq,
    AUTHOR => 'Benjamin Trott <ben@rhumba.pair.com>',
    ABSTRACT => 'On-disk management of public and private keyfiles',
);

sub read_yes_or_no {
    my($prompt, $def) = @_;
    my $ans = prompt($prompt, $def);
    $ans =~ /^y/i;
}

sub check_module {
    my($name, $ver, $missing) = @_;
    print substr("$name ............................", 0, 30);
    my $ok = have_mod($name, $ver);
    $$missing++ unless $ok;
    print $ok ? "ok\n" : "** FAILED **\n";
    $ok;
}

sub have_mod {
    my($name, $ver) = @_;
    eval("use $name" . ($ver ? " $ver;" : ";"));
    !$@;
}
