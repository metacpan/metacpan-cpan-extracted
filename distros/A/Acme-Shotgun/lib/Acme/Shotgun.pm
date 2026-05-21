package Acme::Shotgun;

# ABSTRACT: Shoots holes in files

use strict;
use warnings;

our $VERSION = '0.03';

sub new {
    my ($class, %args) = @_;

    my $self = {
        type       => 'double',
        load       => 'bird',
        shots      => undef,
        quiet      => 0,
        debug      => 0,
        verbose    => 1,
        num_rounds => 0,
        %args,
    };

    die "Invalid shotgun type '$self->{type}'! Must be 'double' or 'pump'.\n"
        unless $self->{type} =~ /^(?:double|pump)$/;

    die "Invalid ammo type '$self->{load}'! Must be 'bird', 'buck', or 'slug'.\n"
        unless $self->{load} =~ /^(?:bird|buck|slug)$/;

    $self->{verbose}++ if $self->{debug};
    $self->{verbose} = 0 if $self->{quiet};

    bless $self, $class;
    $self->reload();

    return $self;
}

sub reload {
    my $self = shift;

    my $num_rounds = $self->{type} eq 'pump' ? 5 : 2;
    $num_rounds = $self->{shots}
        if $self->{shots} && $self->{shots} < $num_rounds;

    $self->{num_rounds} = $num_rounds;

    print "Loading $num_rounds round(s)...\n" if $self->{verbose};
    print "Shotgun reloaded!\n";
    $self->check() if $self->{verbose};

    return $self;
}

sub check {
    my $self = shift;
    printf "type: %s  load: %s  rounds: %d\n",
        $self->{type}, $self->{load}, $self->{num_rounds};
    return $self;
}

sub fire {
    my ($self, %args) = @_;

    my $target = $args{target}
        or die "No target specified!\n";

    die "Target file does not exist: $target\n"       unless -e $target;
    die "Target file must be a plain file: $target\n"  unless -f $target;
    die "Target file must be under 1 GB: $target\n"
        if -s $target > (1024 * 1024);

    if ($self->{num_rounds} == 0) {
        print "Mag empty, you'll need to reload!\n";
        return $self;
    }

    while ($self->{num_rounds} > 0) {
        $self->_shoot($target);
        $self->{num_rounds}--;
    }

    return $self;
}

## Private methods

sub _shoot {
    my ($self, $target) = @_;

    if ($self->{debug}) {
        print "POW! (debug - no file modified)\n";
        return;
    }

    open my $in, '<', $target or die "Unable to open target file: $target\n";
    my @lines = <$in>;
    close $in;

    my $height   = scalar @lines;
    my $width    = 80;
    my $v_buffer = int rand($height);
    my $h_buffer = int rand($width);
    my $v_spread = 7;
    my $h_spread = 13;
    my $r        = int rand(3);

    for my $v (0 .. $v_spread - 1) {
        my $v_offset = $v_buffer + $v;
        last if $v_offset >= $height;

        my @line = split '', $lines[$v_offset];

        for my $h (0 .. $h_spread - 1) {
            my $h_offset = $h_buffer + $h;
            last if $h_offset >= @line;
            last if $line[$h_offset] eq "\n";

            if ($self->{load} eq 'buck') {
                $line[$h_offset] = ' '
                    if grep { $_ == $h } @{ _buck_pattern($r)->{$v} // [] };
            } elsif ($self->{load} eq 'slug') {
                $line[$h_offset] = ' '
                    if grep { $_ == $h } @{ _slug_pattern($r)->{$v} // [] };
            } else {
                $line[$h_offset] = ' '
                    if grep { $_ == $h } @{ _bird_pattern($r)->{$v} // [] };
            }

            $lines[$v_offset] = join('', @line);
        }
    }

    open my $fh, '>', $target or die "Unable to open target file: $target\n";
    print $fh $_ for @lines;
    close $fh;

    print "POW!\n" unless $self->{quiet};
}

## Shot pattern data

sub _buck_pattern {
    my $r = shift;
    my @patterns = (
        { 0=>[6,7], 1=>[1,2,6,7], 2=>[1,2,11,12], 3=>[6,7,11,12],
          4=>[1,2,6,7], 5=>[1,2,9,10], 6=>[9,10] },
        { 0=>[1,2,9,10], 1=>[1,2,9,10], 2=>[5,6], 3=>[1,5,6,10,11],
          4=>[1,2,10,11], 5=>[6,7], 6=>[6,7] },
        { 0=>[5,6,7], 1=>[1,2,6,10,11], 2=>[1,2,10,11], 3=>[5,6,7],
          4=>[1,2,6], 5=>[1,2,10], 6=>[9,10] },
    );
    return $patterns[$r];
}

sub _slug_pattern {
    my $r = shift;
    my @patterns = (
        { 0=>[5,6,7], 1=>[5,6] },
        { 0=>[5,6],   1=>[5,6,7] },
        { 0=>[5,6],   1=>[4,5,6] },
    );
    return $patterns[$r];
}

sub _bird_pattern {
    my $r = shift;
    my @patterns = (
        { 0=>[6], 1=>[3,9], 2=>[6], 3=>[3], 4=>[1,6,10], 5=>[4], 6=>[0,7] },
        { 0=>[6], 1=>[3,9], 2=>[6,11], 3=>[3,7,9], 4=>[6,10],
          5=>[4,9], 6=>[7,11] },
        { 0=>[6,9], 1=>[2,4,7], 2=>[5,9], 3=>[1,7], 4=>[6],
          5=>[3,6,9], 6=>[5] },
    );
    return $patterns[$r];
}

1;

__END__

=head1 NAME

Acme::Shotgun - Shoots holes in files

=head1 SYNOPSIS

    use Acme::Shotgun;

    my $gun = Acme::Shotgun->new(
        type  => 'double',   # double | pump
        load  => 'bird',     # bird | buck | slug
        quiet => 0,
        debug => 0,
    );

    $gun->reload();
    $gun->check();
    $gun->fire(target => '/path/to/file.txt');

=head1 DESCRIPTION

Acme::Shotgun is an object-oriented Perl module that shoots holes in plain
text files. Supports double-barrel and pump-action shotgun types, with
birdshot, buckshot, and slug ammunition - each producing a distinct damage
pattern in the target file.

Magazine state is kept in the object itself, so rounds are tracked for the
lifetime of the object.

=head1 METHODS

=head2 new(%args)

Constructs and returns a new Acme::Shotgun object. The gun is automatically
reloaded on construction.

    my $gun = Acme::Shotgun->new(
        type    => 'double',  # 'double' (default) or 'pump'
        load    => 'bird',    # 'bird' (default), 'buck', or 'slug'
        shots   => undef,     # optional: cap the number of rounds loaded
        quiet   => 0,         # suppress all output
        debug   => 0,         # dry-run mode, no file modifications
        verbose => 1,         # verbose output (disabled automatically if quiet)
    );

Dies with an error if an invalid C<type> or C<load> value is given.

=head2 reload()

Loads the magazine for the current shotgun type and ammunition. Default
capacity is 2 rounds for C<double> and 5 rounds for C<pump>. If C<shots>
was set in the constructor and is less than the default capacity, it is
used instead.

Prints a loading message and the resulting mag state when C<verbose> is on.
Returns the object for chaining.

=head2 check()

Prints the current magazine state - shotgun type, ammunition type, and
remaining round count. Returns the object for chaining.

=head2 fire(target => $path)

Fires all remaining rounds at the given target file, shooting holes into
it with each shot. The file must be an existing plain text file under 1 GB.
Each shot prints C<POW!> unless C<quiet> is set.

In C<debug> mode, C<POW!> is still printed but no file modifications are
made. Returns the object for chaining.

=head1 REFERENCE

=head2 Shotgun Types

=over 4

=item B<double>

Double-barrel. Holds 2 rounds by default. This is the default type.

=item B<pump>

Pump-action. Holds 5 rounds by default.

=back

=head2 Ammunition Types

=over 4

=item B<bird>

Birdshot. Sparse, scattered pellet holes spread across the target area.
This is the default ammunition type.

=item B<buck>

Buckshot. Denser, clustered hole patterns - more destructive than birdshot.

=item B<slug>

Slug. A tight, concentrated blast with minimal spread.

=back

=head1 AUTHOR

John R.

=head1 LICENSE

Same terms as Perl itself.

=cut
