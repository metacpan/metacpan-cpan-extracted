###############################################################################
# Captcha::Stateless::Text module for Perl.
# Copyright (C) 2024, Lester Hightower <hightowe@cpan.org>
###############################################################################

package Captcha::Stateless::Text;

use strict;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Sub::Util qw(set_subname);   # core
use MIME::Base64 qw();           # core
use Digest::MD5 qw(md5_hex);     # core
use Data::Dumper;                # core
use Try::Tiny;                   # libtry-tiny-perl
use Crypt::Mode::CBC;            # libcryptx-perl
use JSON qw(to_json from_json);  # libjson-perl
use Lingua::EN::Nums2Words;      # From CPAN (cpanm Lingua::EN::Nums2Words)
$Data::Dumper::Sortkeys = 1;
Lingua::EN::Nums2Words::set_case('lower');

our $VERSION = "0.4";
sub Version { $VERSION; }

my %QAfuncs = {}; # Holds our private __ANON__ subroutines

sub new {
  my $class = shift;
  my $self = {
    cipher => 'AES',
    iv  => 'gkbx5g9hsvhqrosg',                 # Must be 16 bytes / 128 bits
    key => 'tyDjb39dQ20pdva0lTpyuiowWfxSSwa9', # 32 bytes / 256 bits (AES256)
    ep_pre => 'captcha'.lc(substr(md5_hex(__PACKAGE__), 0, 6)).'.',
  };
  bless $self, $class;
  return $self;
}

#############################################################################
# Object parameter get/set functions ########################################
#############################################################################
sub get_ep_pre($self)           { return $self->{ep_pre}; }
sub set_self_val($self, $k, $v) { $self->{$k} = $v; }
sub set_cipher($self, $v)       { set_self_val($self, 'cipher', $v); }
sub set_iv($self, $v)           { set_self_val($self, 'iv', $v); }
sub set_key($self, $v)          { set_self_val($self, 'key', $v); }

#############################################################################
# Crypto functions ##########################################################
#############################################################################
sub encrypt_b64($self, $data) {
  my $d = my_crypt_cbc($self, 'encrypt', $self->{cipher}, $self->{key}, $self->{iv}, $data);
  return MIME::Base64::encode_base64url($d, ''); # '' for no line breaks
}
sub decrypt_b64($self, $data) {
  my $d = MIME::Base64::decode_base64url($data);
  return my_crypt_cbc($self, 'decrypt', $self->{cipher}, $self->{key}, $self->{iv}, $d);
}
# Helper function to centralize and reduce code duplication
sub my_crypt_cbc($self, $mode, $cipher, $key, $iv, $data) {
  my $pkg = __PACKAGE__;

  my $cbc = Crypt::Mode::CBC->new($cipher, 1);
  if ($mode eq 'encrypt') {
    my $payload = undef;
    try {
      $payload = $cbc->encrypt($data, $key, $iv); # ENCRYPT
    } catch {
      warn("$pkg my_crypt_cbc() failed to $mode with error: $_");
      $payload = undef;
    };
    return $payload;
  } elsif ($mode eq 'decrypt') {
    my $payload = undef;
    try {
      $payload = $cbc->decrypt($data, $key, $iv); # DECRYPT
    } catch {
      warn("$pkg my_crypt_cbc() failed to $mode with error: $_");
      $payload = undef;
    };
    return $payload;
  }
  return undef;
}
#############################################################################
#############################################################################

#############################################################################
# Captcha creation functions ################################################
#############################################################################
sub getQA_chars {
  my $qa = $QAfuncs{chars}(@_);
  $_[0]->add_enc_payload($qa);
  return $qa;
}
sub getQA_math {
  my $qa = $QAfuncs{math}(@_);
  $_[0]->add_enc_payload($qa);
  return $qa;
}
sub add_enc_payload($self, $qa) {
  # Make and add the enc_payload
  my $payload_json = to_json($qa);
  my $enc_payload = $self->encrypt_b64($payload_json);
  $qa->{enc_payload} = $self->{ep_pre} . $enc_payload;
}
sub validate($self, $answer, $enc_payload) {
  my $ep_pre = $self->{ep_pre};
  return 0 if (!(defined($enc_payload) && length($enc_payload)));
  return 0 if ($enc_payload !~ m/^\Q$ep_pre\E/); # Invalid payload
  $enc_payload =~ s/^\Q$ep_pre\E//; # Trim the prefix
  my $payload = $self->decrypt_b64($enc_payload);
  return 0 if (!defined($payload));
  my $qa = from_json($payload);
  return 1 if ($qa->{a} =~ m/^\d+$/ && $answer == $qa->{a});
  return 1 if ($answer eq $qa->{a});
  return 0;
}

#############################################################################
# The subs in %QAfuncs are not callable by the outside world because they are
# __ANON__ and not in the Perl sumbol table.
#############################################################################
$QAfuncs{chars} = set_subname(__PACKAGE__."-private:getQA_chars", sub {
  my $self = shift @_;
  my $q_len = shift @_ // 6;
  my $a_len = shift @_ // 3;
  my $q_sort = shift @_ // 1;
  # Protects again non-sense that will cause an infinite loop.
  if ($a_len > $q_len) { $q_len = $a_len + 4; }
  # Build up the question characters
  my @q_chars = ();
  my @src_chars = ('A'..'Z');
  while (scalar(@q_chars) < $q_len) {
    my $char = $src_chars[int(rand(scalar(@src_chars)))];
    push @q_chars, $char;
  }
  # Build the list of "indexes" of answers in the question
  my @a_idxes = ();
  while (scalar(@a_idxes) < $a_len) {
    my $indx = int(rand(scalar(@q_chars)));
    my $indx_plus_1 = $indx + 1; # Humans start with 1s not 0s
    next if (grep(/^\Q$indx_plus_1\E$/, @a_idxes)); # No duplicates
    push @a_idxes, $indx_plus_1;
  }
  my @a_idxes = sort @a_idxes if ($q_sort); # Sort for user convenience
  my @a_chars = map { $q_chars[($_-1)] } @a_idxes; # The answer chars
  my @a_idxws = map { num2word_ordinal($_) } @a_idxes; # num2word them

  my $q_prompt = join(', ', @a_idxws);
  $q_prompt =~ s/, (\w+)$/, and $1/;     # Place the word and
  $q_prompt =~ s/,// if ($#a_idxws < 2); # Kill an unneeded comma
  my $q_str = "Provide the $q_prompt characters from ".
	join('-', @q_chars); # The question
  #my $q_str = join(',', @a_idxes) . " from ".join('-', @q_chars); # The question
  my $a_str = join('', @a_chars); # The answer
  my $qa = {
	q => $q_str,
	a => $a_str,
	};
  return $qa;
});

$QAfuncs{math} = set_subname(__PACKAGE__."-private:getQA_math", sub {
  my $self = shift @_;
  my $ANSWER_MAX = shift @_ // 11;
  my $ANSWER_MIN = shift @_ // 2;
  my @a = (1..15);
  my @b = @a;
  my @QA = ();
  # Build additions then subtractions
  for my $neg (qw(0 1)) {
    foreach my $a (@a) {
      foreach my $b (@b) {
        my $que = undef;
        if ($neg) {
          $que = "$a - $b";
        } else {
          $que = "$a + $b";
        }
        my $ans = eval " $que ";
        if ($ans <= $ANSWER_MAX && $ans >= $ANSWER_MIN) {
          push @QA, { q => $que, a => $ans };
        }
      }
    }
  }
  # Choose a random one to return
  my $qa = $QA[int(rand(scalar(@QA)))];
  return $qa;
});

1;

###############################################################################
# PERL POD ####################################################################
###############################################################################

=head1 NAME

Captcha::Stateless::Text - stateless, text-based CAPTCHAs

=head1 DESCRIPTION

A module to make stateless, text-based CAPTCHAs easy to implement.
It supports:

 * Simple math:
     "7 + 3 = ?"
     answer = 10
 * Character selection:
     "Provide the second, third, and sixth characters from B-G-Q-E-O-S"
     answer = GQS

=head1 SYNOPSIS

 use Captcha::Stateless::Text;

 my $captcha = Captcha::Stateless::Text->new();

 # Recommend setting these to values that *you* derive
 # Must be 16 bytes / 128 bits
 $captcha->set_iv('gkbx5g9hsvhqrosg');
 # 32 bytes / 256 bits for AES256
 $captcha->set_key('tyDjb39dQ20pdva0lTpyuiowWfxSSwa9');

 # Grab a question/answer data structure
 my $qa = $captcha->getQA_chars();
 #    __or__
 my $qa = $captcha->getQA_math();

 # For getQA_chars(), $qa will look similar to this:
 my $qa_chars = {
   'q' => 'Provide the first and fifth characters from A-W-N-Z-L-X'
   'a' => 'AL',
   'enc_payload' => <<base-64 and url-encoded encrypted data>>,
 },
 # For getQA_math(), $qa will look similar to this:
 my $qa_math = {
   'q' => '7 + 3',
   'a' => '10',
   'enc_payload' => <<base-64 and url-encoded encrypted data>>,
 };

 # Your job now is to present the user with the question ($qa->{q}), to
 # not lose the enc_payload (use a HTML <input type="hidden"> field), to
 # collect the user's answer, and then validate it, like this:
 my $is_valid = $captcha->validate($user_answer, $enc_payload_from_qa);
 if ($is_valid) {
   print "You win!\n";
 } else {
   print "You lose!\n";
 }

=head1 SUBROUTINES

The two subroutines that generate the questions and answers have a few
options that can be specified to control their behavior.

 my $qa = $captcha->getQA_chars($q_len, $a_len, $q_sort);

 OPT   DEFAULT DESCRIPTION
 --------------------------------------------------------------------
 $q_len   6    The character length of the question string.
 $a_len   3    The number of characters in the answer.
 $q_sort  1    Sort the answer characters, so that users will always
               be asked for characters flowing left-to-right, or
               require them to "jump around" in the question string.

 my $qa = $captcha->getQA_math($a_max, $a_min);

 OPT   DEFAULT DESCRIPTION
 --------------------------------------------------------------------
 $a_max  11    The maximum value of the answer.
 $a_min   2    The minimum value of the answer.

=head1 COPYRIGHT

Copyright (C) 2024, Lester Hightower <hightowe@cpan.org>

=head1 LICENSE

This software is licensed under the OSI certified Artistic License,
one of the licenses of Perl itself.

L<http://en.wikipedia.org/wiki/Artistic_License>

=cut

###############################################################################

