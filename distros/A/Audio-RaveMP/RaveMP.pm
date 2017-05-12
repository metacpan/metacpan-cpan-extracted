package Audio::RaveMP;

use DynaLoader ();

$VERSION = "0.04";

@ISA = qw(DynaLoader);

__PACKAGE__->bootstrap($VERSION);

if ((caller)[0] eq 'Xmms') {
    eval join '', <DATA>;
    print $@ if $@;
    unless (defined &Xmms::is_cpl) {
	*Xmms::is_cpl = sub {0};
    }
}

my %FileDesc = (
    'D' => "Start of Document file",
    'd' => "Additional Document file block",
    'E' => "Start of 'Other File' type",
    'e' => "Additional 'Other File' block",
    'F' => "FAT",
    'M' => "MP3 File",
    'm' => "Additional MP3 file block",
    'P' => "Start of PCM File",
    'p' => "Additional PCM file block",
    'T' => "Start of Telephone File",
    't' => "Additional Telephone file block",
);

sub Audio::RaveMPSlot::file_description {
    my $slot = shift;
    $FileDesc{$slot->type};
}

1;

__DATA__

#Xmms::shell plugin
package Xmms::Cmd;

#require Xmms 0.09;

my $rmp = ravemp_init();
my $files_cache;
my $file_slots = {};

sub ravemp_init {
    eval {
	require Audio::RaveMPClient;
	$rmp = Audio::RaveMPClient->new;
    };

    if ($rmp) {
	return $rmp;
    }
    else {
	print Xmms::highlight(Warn => "RaveMP: Connect to server failed\n");
    }

    $rmp = Audio::RaveMP->new;
    unless ($rmp->permitted) {
	print Xmms::highlight(Error => "RaveMP: $!\n");
	$rmp = undef;
	return;
    }
    unless ($rmp->is_ready) {
	print Xmms::highlight(Warn => "RaveMP: Device is not ready\n");
    }
    $rmp->show_status(1);

    $rmp;
}

sub ravemp_track {
    $rmp ||= ravemp_init();
    my $contents = $rmp->contents;
    my @retval;
    for my $slot (@$contents) {
	push @retval, sprintf "%d - %s", $slot->number, $slot->filename;
    }
    print {Xmms::pager} join "\n", @retval, ""
}

sub ravemp_delete ($) {
    my($self, $arg) = @_;

    if (Xmms::is_cpl()) {
	my $files = Audio::RaveMP::files();
	return grep /^$arg/, @$files;
    }

    if ($arg eq 'all') {
	for (@{ Audio::RaveMP::files() }) {
	    Xmms::Cmd->ravemp_delete($_);
	}
	return;
    }

    my $number;
    if ($arg =~ /^\d+$/) {
	$number = $arg;
    }
    else {
	$number = $file_slots{$arg};
    }

    my $filename = $rmp->filename($number);
    unless ($filename) {
	print Xmms::highlight(Error => "no mp3 in slot $number\n");
    }
    if ($rmp->remove($number)) {
	print "$filename removed\n";
    }
    else {
	print "failed to remove $filename\n";
    }
    Audio::RaveMP::files_uncache();
}

sub ravemp_upload ($;$) {
    my($self, $arg) = @_;

    my($file, $name) = split /\s+/, $arg;

    my @files = Xmms::filecomplete($file);

    return @files if Xmms::is_cpl();
    $name = "" if @files > 1;

    for $file (@files) {
        my $base = Xmms::basename($file);
        $name = @files > 1 ? $base : $name || $base;

        print "uploading $file to $name...";
        if ($rmp->upload($file, $name)) {
	    print "done\n";
        }
        else {
	    print "failed\n";
        }
    }

    Audio::RaveMP::files_uncache();
}

sub Audio::RaveMP::files {
    return $files_cache if $files_cache;
    Audio::RaveMP::files_uncache();

    my $contents = $rmp->contents;
    my @retval;

    for my $slot (@$contents) {
	my $filename = $slot->filename; 
	$file_slots{$filename} = $slot->number;
	push @retval, $filename;
    }

    $files_cache = \@retval;
}

sub Audio::RaveMP::files_uncache {
    $files_cache = "";
    %file_slots = ();
}

sub ravemp_download ($;$) {
    my($self, $arg) = @_;
    my($file, $name) = split /\s+/, $arg;

    if (Xmms::is_cpl()) {
	my $files = Audio::RaveMP::files();
	if (grep { $_ eq $file } @$files) {
	    return Xmms::filecomplete($name);
	}

	return grep /^$arg/, @$files;
    }

    $name ||= Xmms::basename($file);
    if (-d $name) {
	$name .= Xmms::basename($file);
    }

    print "downloading `$file' to $name...";
    if ($rmp->download($file_slots{$file}, $name)) {
	print "done\n";
    }
    else {
	print "failed\n";
    }
}

1;
__END__

=head1 NAME

Audio::RaveMP - Perl interface to Sensory Science RaveMP player

=head1 SYNOPSIS


  use Audio::RaveMP ();

=head1 DESCRIPTION

The Audio::RaveMP module provides a Perl interface to the Sensory
Science RaveMP player.

=head1 METHODS

=over 4

=item new

 my $rmp = Audio::RaveMP->new;

=item permitted

Check parallel port permissions (must be root at the moment):

 unless ($rmp->permitted) {
     print "$!\n";
     exit 1;
 }

=item is_ready

Check that RaveMP is connected and powered up:

 unless ($rmp->is_ready) {
      print "Device is not ready (not connected or powered up?)\n";
      exit 2;
 }

=item show_status

Show status messages:

 $rmp->show_status(1);

 $rmp->show_status(0);

=item upload

Upload a file.  The second argument is the name to upload to, which is 
optional and defaults to the upload name:

 unless ($rmp->upload("we_eat_rhythm.mp3")) {
      print "upload failed\n";
 }

 unless ($rmp->upload("we_eat_rhythm.mp3", "We Eat Rhythm")) {
      print "upload failed\n";
 }

=item remove

Remove a file specified by the give slot number:

 unless ($rmp->remove(8)) {
     print "unable to remove file at slot 8\n";
 }

=item download

Download the file specified by the give slot number.  The last
argument is the name of the destination file, which is optional and
defaults to the name of the downloaded file:

 unless ($rmp->download("we_eat_rhythm.mp3")) {
      print "download failed\n";
 }

 unless ($rmp->download("We Eat Rhythm", "we_eat_rhythm.mp3")) {
      print "download failed\n";
 }

=item contents

Return an array reference of file contents in the player.  Each
element is an object blessed into the I<Audio::RaveMPSlot> class:

 my $contents = $rmp->contents;
 for my $slot (@$contents) {
     printf "%d, %s -> %s\n", 
            $slot->number, $slot->type, $slot->filename;
 }

=back

=head2 The Audio::RaveMPSlot Class

=over 4

=item number

The slot number:

 my $number = $slot->number;

=item type

The file type:

 my $type = $slot->type;

=item filename

The filename:

 my $filename = $slot->filename;

=item remove

Remove file in the given slot:

 $slot->remove;

=item download

Download the file in the given slot:

 $slot->download;

=back

=head1 Audio::RaveMPServer

Access to the parallel port requires root permissions.  To "minimize
risk", a client/server package is included where the server runs as
root and client runs as any user.  Access to the server is restricted
to the loopback address (127.0.0.1).  To use the server you must
install the I<PlRPC> and I<Net::Daemon> packages from CPAN.  To start
the server:

 % sudo perl -MAudio::RaveMPServer -s start

The same client API is used to talk to the server, the name is simply
changed from I<Audio::RaveMP> to I<Audio::RaveMPClient>:

 use Audio::RaveMPClient ();
 my $rmp = Audio::RaveMPClient->new;

=head1 Xmms::shell plugin

To enable the Xmms::shell plugin, add the following line
to your ~/.xmms/.perlrc:

 +require Audio::RaveMP

The following commands become available in the shell:

=over 4

=item ravemp_track

List mp3 files in the player:

 xmms> ravemp_track

=item ravemp_upload

Upload files:

 xmms> ravemp_upload /usr/local/mp3/prodigy/what_evil_lurks/*.mp3

=item ravemp_download

Download files specified by slot or filename:

 xmms> ravemp_download rythm_of_life.mp3.mp3 ~/mp3/

=item ravemp_delete

Remove files from the player specified by slot or filename:

 xmms> ravemp_delete rythm_of_life.mp3

To remove all files from the player:

 xmms> ravemp_delete all

=back

=head1 SEE ALSO

Xmms(3)

=head1 AUTHOR

Doug MacEachern

ravemp.c derived from "ravemp-0.0.2" by:
The Snowblind Alliance: http://www.world.co.uk/sba/
