package Brackup::Decrypt;

use strict;
use warnings;
use Carp qw(croak);
use Brackup::Util qw(slurp tempfile);

# Decrypt a dataref into a dataref
sub decrypt_data {
    my ($dataref, %opts) = @_;

    my $meta = $opts{meta};

    # do nothing if the data is not encrypted
    return $dataref unless $meta && $meta->{"GPG-Recipient"};

    my $dataref_temp    = ( (tempfile())[1] || die );
    write_to_file($dataref_temp, $dataref);

    my $decrypted_temp = decrypt_file($dataref_temp,%opts);
    unlink($dataref_temp);

    my $data = slurp($decrypted_temp);
    unlink($decrypted_temp);

    return \$data;
}

sub write_to_file {
    my ($file, $ref) = @_;
    open (my $fh, '>', $file) or die "Failed to open $file for writing: $!\n";
    print $fh $$ref;
    close($fh) or die;
    die "File is not of the correct size" unless -s $file == length $$ref;
    return 1;
}

sub decrypt_file_if_needed {
    my ($filename) = @_;

    my $meta = slurp($filename, decompress => 1);
    if ($meta =~ /[\x00-\x08]/) {  # silly is-binary heuristic
        my $new_file = decrypt_file($filename,no_batch => 1);
        if (defined $new_file) {
          warn "Decrypted ${filename} to ${new_file}.\n";
        }
        return $new_file;
    }
    return undef;
}

# Decrypt a file into a new file
# Return the new file's name, or undef.

our $warned_about_gpg_agent = 0;

sub decrypt_file {
  my ($encrypted_file,%opts) = @_;

  my $no_batch = delete $opts{no_batch};
  my $meta     = delete $opts{meta};
  croak("Unknown options: " . join(', ', keys %opts)) if %opts;

  # find which key we're using to decrypt it
  if ($meta) {
      my $rcpt = $meta->{"GPG-Recipient"} or
          return undef;
  }

  unless ($ENV{'GPG_AGENT_INFO'} ||
          @Brackup::GPG_ARGS ||
          $warned_about_gpg_agent++)
  {
      my $err = q{
                      #
                      # WARNING: trying to restore encrypted files,
                      # but $ENV{'GPG_AGENT_INFO'} not present.
                      # Are you running gpg-agent?
                      #
                  };
      $err =~ s/^\s+//gm;
      warn $err;
  }

  my $output_temp = ( (tempfile())[1] || die );

  my @list = ("gpg", @Brackup::GPG_ARGS,
              "--use-agent",
              !$opts{no_batch} ? ("--batch") : (),
              "--trust-model=always",
              "--output",  $output_temp,
              "--yes", "--quiet",
              "--decrypt", $encrypted_file);
  system(@list)
      and die "Failed to decrypt with gpg: $!\n";

  return $output_temp;
}

1;
