package Brackup::Config;

use strict;
use Brackup::ConfigSection;
use warnings;
use Carp qw(croak);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub add_section {
    my ($self, $sec) = @_;
    $self->{$sec->name} = $sec;
}

sub get_section {
    my ($self, $name) = @_;
    return $self->{$name};
}

sub load {
    my ($class, $file) = @_;
    $file ||= Brackup::Config->default_config_file_name;

    my $self = bless {}, $class;

    open (my $fh, $file) or do {
        if (write_dummy_config($file)) {
            die "Your config file needs tweaking.  I put a commented-out template at: $file\n";
        } else {
            die "No config file at: $file\n";
        }
    };
    my $sec = undef;
    my %inherit = ();
    while (my $line = <$fh>) {
        $line =~ s/^\#.*//;   # kill comments starting at beginning of line
        $line =~ s/\s\#.*//;   # kill comments with whitespace before the # (motivation: let # be in regexps)
        $line =~ s/^\s+//;
        $line =~ s/\s$//;
        next unless $line ne "";

        if ($line =~ /^\[(.+)\]$/) {
            my $name = $1;
            $sec  = Brackup::ConfigSection->new($name);
            die "Duplicate config section '$name'" if $self->{$name};
            $self->{$name} = $sec;
        } elsif ($line =~ /^(\w+)\s*=\s*(.+)/) {
            die "Declaration of '$1' outside of a section." unless $sec;
            if ($1 eq 'inherit') {
              $inherit{$sec->name} = $2;
            } else {
              $sec->add($1, $2);
            }
        } else {
            die "Bogus config line: $line";
        }
    }

    unless ($sec) {
        die "Your config file needs tweaking.  There's a starting template at: $file\n";
    }

    # Config section inheritance
    my $loop_count = 0;
    while (keys %inherit) {
      for my $child_sec (keys %inherit) {
        # If this parent_sec itself inherits from something else, defer this time around
        next if exists $inherit{ $inherit{$child_sec} };

        my $parent_sec = delete $inherit{$child_sec};
        # If missing, derive prefix ([SOURCE|TARGET]:) from section name
        $parent_sec = (split /:/, $child_sec, 2)[0] . ':' . $parent_sec
          if $parent_sec !~ m/:/;
        die "Cannot inherit from unknown section '$parent_sec'." unless $self->{$parent_sec};
        $self->inherit_from($self->{$parent_sec}, $self->{$child_sec});
      }
      die "Inheritance chain too long - looping?" if ++$loop_count > 20;
    }

    return $self;
}

sub default_config_file_name {
    my ($class) = @_;

    if ($ENV{HOME}) {
        # Default for UNIX folk
        return "$ENV{HOME}/.brackup.conf";
    }
    elsif ($ENV{APPDATA}) {
        # For Windows users
        return "$ENV{APPDATA}/brackup.conf";
    }
    else {
        # Fall back on the current directory
        return "brackup.conf";
    }

}

sub write_dummy_config {
    my $file = shift;
    sysopen (my $fh, $file, O_WRONLY | O_CREAT | O_EXCL, 0600) or return;
    print $fh <<ENDCONF;
# This is an example config

#[TARGET:raidbackups]
#type = Filesystem
#path = /raid/backup/brackup
#keep_backups = 10

#[TARGET:amazon]
#type = Amazon
#aws_access_key_id  = XXXXXXXXXX
#aws_secret_access_key =  XXXXXXXXXXXX
#keep_backups = 10

#[SOURCE:proj]
#path = /raid/bradfitz/proj/
#chunk_size = 5m
#gpg_recipient = 5E1B3EC5

#[SOURCE:bradhome]
#path = /raid/bradfitz/
#noatime = 1
#chunk_size = 64MB
#ignore = ^\.thumbnails/
#ignore = ^\.kde/share/thumbnails/
#ignore = ^\.ee/minis/
#ignore = ^build/
#ignore = ^(gqview|nautilus)/thumbnails/

ENDCONF
}

sub load_root {
    my ($self, $name, $cache) = @_;
    my $conf = $self->{"SOURCE:$name"} or
        die "Unknown source '$name'\n";

    my $root = Brackup::Root->new($conf, $cache);

    # iterate over config's ignore, and add those
    foreach my $pat ($conf->values("ignore")) {
        $root->ignore($pat);
    }

    # common things to ignore
    $root->ignore(qr!~$!);
    $root->ignore(qr!^\.thumbnails/!);
    $root->ignore(qr!^\.kde/share/thumbnails/!);
    $root->ignore(qr!^\.ee/minis/!);
    $root->ignore(qr!^\.(gqview|nautilus)/thumbnails/!);

    # abort if the user had any configuration we didn't understand
    if (my @keys = $conf->unused_config) {
        die "Aborting, unknown configuration keys in SOURCE:$name: @keys\n";
    }

    return $root;
}

sub list_sources {
    my ($self) = @_;
    return sort map { s/^SOURCE://; $_ } grep(/^SOURCE:/, keys %$self);
}

sub list_targets {
    my ($self) = @_;
    return sort map { s/^TARGET://; $_ } grep(/^TARGET:/, keys %$self);
}

sub load_target {
    my ($self, $name, %opts) = @_;
    my $testmode = delete $opts{testmode};
    croak("Unknown options: " . join(', ', keys %opts)) if %opts;

    my $confsec = $self->{"TARGET:$name"} or
        die "Unknown target '$name'\n";

    my $type = $confsec->value("type") or
        die "Target '$name' has no 'type'";
    die "Invalid characters in ${name}'s 'type'"
        unless $type =~ /^\w+$/;

    my $class = "Brackup::Target::$type";
    eval "use $class; 1;" or die
        "Failed to load ${name}'s driver: $@\n";
    my $target = $class->new($confsec);

    if (my @unk_config = $confsec->unused_config) {
        die "Unknown config params in TARGET:$name: @unk_config\n"
             unless $testmode;
    }
    return $target;
}

# Copy all keys in $parent_sec that don't exist in $child_sec
sub inherit_from {
    my ($self, $parent_sec, $child_sec) = @_;

    for my $key ($parent_sec->keys) {
      next if $child_sec->values($key);
      $child_sec->add($key, $_) foreach $parent_sec->values($key);
    }
}

1;

__END__

=head1 NAME

Brackup::Config - configuration parsing/etc

=head1 CONFIGURATION INFO

For instructions on how to configure Brackup, see:

L<Brackup::Manual::Overview>

L<Brackup::Root>

L<Brackup::Target>




