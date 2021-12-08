# -*- mode: perl -*-
# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

App::Phoebe::Oracle - an anonymous question asking game

=head1 DESCRIPTION

By default, Phoebe creates a wiki editable by all. With this extension, the
C</oracle> space turns into a special site: if you have a client certificate,
you can pose questions and get answers.

When you ask a question, you can delete any answers on it, and the question
itself. Once it has gotten three answers, it is hidden from view and only you
can decide wether to delete it, or whether to publish it. If the question is no
longer waiting for answers, deleting every answer deletes the question, too.

You can only answer questions not your own. You can answer every question just
once (even if you or the question asker deletes your answer, there is no going
back). You can delete your answer. If the question is no longer waiting for
answers, deleting the last answer deletes the question, too.

Simply add it to your F<config> file. If you are virtual hosting, name the host
or hosts for your capsules.

    package App::Phoebe::Oracle;
    use Modern::Perl;
    our @oracle_hosts = qw(transjovian.org);
    use App::Phoebe::Oracle;

If you don't want to use C</oracle> for the game, you can change it:

    our $oracle_space = 'truth';

If you want to change the maximu number of answers that a question may have:

    our $max_answers = 5;

If you want to notify Antenna whenever a new question has been asked:

    use App::Phoebe qw($log);
    use IO::Socket::SSL;
    # a very simple Gemini client
    sub query {
      my $url = shift;
      my($scheme, $authority, $path, $query, $fragment) =
	$url =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(\S*))?|;
      my ($host, $port) = split(/:/, $authority);
      my $socket = IO::Socket::SSL->new(
	PeerHost => $host, PeerPort => $port||1965,
	# don't verify the server certificate
	SSL_verify_mode => SSL_VERIFY_NONE, );
      $socket->print($url);
      local $/ = undef; # slurp
      return <$socket>;
    }
    # wrap the save_data sub in our own code
    *old_save_oracle_data = \&App::Phoebe::Oracle::save_data;
    *App::Phoebe::Oracle::save_data = \&new_save_oracle_data;
    # call Antenna after saving
    sub new_save_oracle_data {
      old_save_oracle_data(@_);
      my $gemlog = "gemini://transjovian.org/oracle/log";
      my $res = query("gemini://warmedal.se/~antenna/submit?$gemlog");
      my ($code) = $res =~ /^(\d+)/;
      $log->info("Antenna: $code");
    }

=cut

package App::Phoebe::Oracle;
use App::Phoebe qw($server $log @extensions host_regex port success result print_link wiki_dir with_lock to_url);
use File::Slurper qw(read_binary write_binary);
use Mojo::JSON qw(decode_json encode_json);
use Net::IDN::Encode qw(domain_to_ascii);
use List::Util qw(first any none);
use Encode qw(encode_utf8 decode_utf8);
use POSIX qw(strftime);
use Modern::Perl;
use URI::Escape;
use utf8;

push(@extensions, \&oracle);

our $oracle_space = "oracle";
our @oracle_hosts;
our $max_answers = 3;

sub oracle {
  my $stream = shift;
  my $url = shift;
  my $hosts = oracle_regex();
  my $port = port($stream);
  my ($host, $question, $answer, $number, @numbers);
  if (($host) = $url =~ m!^gemini://($hosts)(?::$port)?/$oracle_space/?$!) {
    return serve_main_menu($stream, $host);
  } elsif (($host) = $url =~ m!^gemini://($hosts)(?::$port)?/$oracle_space/questions$!) {
    return serve_questions($stream, $host);
  } elsif (($host, $question) = $url =~ m!^gemini://($hosts)(?::$port)?/$oracle_space/ask(?:\?([^#]+))?$!) {
    return ask_question($stream, $host, decode_query($question));
  } elsif (($host, $number) = $url =~ m!^gemini://($hosts)(?::$port)?/$oracle_space/question/(\d+)$!) {
    return serve_question($stream, $host, $number);
  } elsif (($host, $number, $answer) =
	   $url =~ m!^gemini://($hosts)(?::$port)?/$oracle_space/question/(\d+)/answer(?:\?([^#]+))?$!) {
    return answer_question($stream, $host, $number, decode_query($answer));
  } elsif (($host, $number) = $url =~ m!^gemini://($hosts)(?::$port)?/$oracle_space/question/(\d+)/publish$!) {
    return publish_question($stream, $host, $number);
  } elsif (($host, $number) = $url =~ m!^gemini://($hosts)(?::$port)?/$oracle_space/question/(\d+)/delete$!) {
    return delete_question($stream, $host, $number);
  } elsif (($host, @numbers) = $url =~ m!^gemini://($hosts)(?::$port)?/$oracle_space/question/(\d+)/(\d+)/delete$!) {
    return delete_answer($stream, $host, @numbers);
  } elsif (($host) = $url =~ m!^gemini://($hosts)(?::$port)?/$oracle_space/log$!) {
    return serve_log($stream, $host);
  }
  return;
}

sub oracle_regex {
  return join("|", map { quotemeta domain_to_ascii $_ } @oracle_hosts) || host_regex();
}

sub load_data {
  my $host = shift;
  my $dir = wiki_dir($host, $oracle_space);
  return [] unless -f "$dir/oracle.json";
  return decode_json read_binary("$dir/oracle.json");
}

sub save_data {
  my ($stream, $host, $data) = @_;
  my $dir = wiki_dir($host, $oracle_space);
  my $bytes = encode_json $data;
  # We don't close the stream on a successful call.
  with_lock($stream, $host, $oracle_space, sub {
    write_binary("$dir/oracle.json", $bytes)});
}

sub new_number {
  my $data = shift;
  while (1) {
    my $n = int(rand(10000));
    return $n unless any { $n eq $_->{number} } @$data;
  }
}

sub decode_query {
  my $text = shift;
  return '' unless $text;
  $text =~ s/\+/ /g;
  return decode_utf8(uri_unescape($text));
}

sub serve_main_menu {
  my ($stream, $host) = @_;
  my $data = load_data($host);
  my $fingerprint = $stream->handle->get_fingerprint();
  success($stream);
  $log->info("Serving oracles");
  $stream->write("# Oracle\n");
  if ($fingerprint) {
    $stream->write("You have an identity or a client certificate picked, so you can ask a question or answer questions by others.\n");
  } else {
    $stream->write("You need to use an identity or pick a client certificate if you want to ask a question or give an answer.\n");
  }
  $stream->write("=> /$oracle_space/ask Ask a question\n");
  $stream->write("=> /$oracle_space/log Check the log\n");
  # skipping answered and unpublished questions, unless you asked the question
  my @questions = grep {
    $_->{status} ne 'answered'
	or $fingerprint and $fingerprint eq $_->{fingerprint}
  } @$data;
  for my $question (@questions) {
    $stream->write("\n\n");
    $stream->write("## Question #$question->{number}\n");
    $stream->write("> " . encode_utf8 $question->{text});
    $stream->write("\n");
    if ($fingerprint and $fingerprint eq $question->{fingerprint}) {
      $stream->write("This is your question.");
      $stream->write(" You need to publish or delete it before you can ask another one.")
	  if $question->{status} ne 'published';
      $stream->write("\n");
      $stream->write("=> /$oracle_space/question/$question->{number} Manage\n");
    } elsif ($question->{status} eq 'asked') {
      if ($fingerprint and any { $fingerprint eq $_->{fingerprint} } @{$question->{answers}}) {
	$stream->write("This question is still looking for answers, but you already gave your answer.\n");
	$stream->write("=> /$oracle_space/question/$question->{number} Take a look\n");
      } else {
	$stream->write("This question is still looking for answers.\n");
	$stream->write("=> /$oracle_space/question/$question->{number} Answer\n");
      }
    } else {
      # it's published
      my $n = grep { $_->{text} } @{$question->{answers}};
      if ($n == 1) {
	$stream->write("This question has one answer.\n");
      } else {
	$stream->write("This question has $n answers.\n");
      }
      $stream->write("=> /$oracle_space/question/$question->{number} Show\n");
    }
  }
  return 1;
}

sub serve_log {
  my ($stream, $host) = @_;
  my $data = load_data($host);
  success($stream);
  $log->info("Serving oracle log");
  $stream->write("# Oracle Log\n");
  my @questions = grep { $_->{status} ne 'answered' } @$data;
  for my $question (@questions) {
    my $text = $question->{text};
    $text =~ s/\n/ /g;
    if (length($text) > 50) {
      $text = substr($text, 0, 50);
      $text =~ s/\s+\S+$/…/ or $text =~ s/\s+$/…/;
    }
    $text = encode_utf8 $text;
    $stream->write("=> /$oracle_space/question/$question->{number} $question->{date} Question #$question->{number}: $text\n");
  }
  return 1;
}

sub serve_questions {
  my ($stream, $host) = @_;
  my $data = load_data($host);
  my $fingerprint = $stream->handle->get_fingerprint();
  return result($stream, "60", "You need a client certificate to list your questions") unless $fingerprint;
  success($stream);
  $log->info("Serving own questions");
  $stream->write("# Oracle\n");
  $stream->write("=> /$oracle_space/ask Ask a question\n");
  my @questions = grep { $_->{fingerprint} eq $fingerprint } @$data;
  for my $question (@questions) {
    $stream->write("\n\n");
    if ($question->{status} eq 'asked') {
      $stream->write("## Asked question #$question->{number}\n");
    } elsif ($question->{status} eq 'answered') {
      $stream->write("## Answered question #$question->{number}\n");
    } elsif ($question->{status} eq 'published') {
      $stream->write("## Published question #$question->{number}\n");
    }
    $stream->write(encode_utf8 $question->{text});
    $stream->write("\n");
    $stream->write("=> /$oracle_space/question/$question->{number} Show answers\n");
  }
  return 1;
}

sub serve_question {
  my ($stream, $host, $number) = @_;
  my $data = load_data($host);
  my $question = first { $_->{number} eq $number } @$data;
  if (not $question) {
    $log->info("Question $number not found");
    return result($stream, "30", to_url($stream, $host, $oracle_space, ""));
  }
  success($stream);
  my $fingerprint = $stream->handle->get_fingerprint();
  if ($question->{status} eq 'answered'
      and (not $fingerprint
	   or $fingerprint ne $question->{fingerprint})) {
    $log->info("Not the owner requesting question $number");
    $stream->write("# Question #$question->{number}\n");
    $stream->write("This question has been answered and it has not been published.\n");
    $stream->write("You are not the owner of this question, which is why you cannot do anything about it.\n");
    $stream->write("Switch identity or pick a different client certificate if you think you are the owner of this question\n");
    $stream->write("=> /$oracle_space/ Back to the oracle\n");
    return;
  }
  $log->info("Serving oracle $question->{number}");
  $stream->write("# Question #$question->{number}\n");
  $stream->write("=> /$oracle_space/ Back to the oracle\n");
  if ($fingerprint) {
    my $n = grep { $_->{text} } @{$question->{answers}};
    if ($fingerprint eq $question->{fingerprint}) {
      $stream->write("=> /$oracle_space/question/$number/delete Delete this question\n");
      if (($question->{status} eq 'asked' and $n > 0)
	  or $question->{status} eq 'answered') {
	$stream->write("=> /$oracle_space/question/$number/publish Publish this question\n");
      }
    } elsif ($n < $max_answers
	     and none { $fingerprint eq $_->{fingerprint} } @{$question->{answers}}) {
      # only allow answers if the undeleted answers is below the maximum, and
      # you haven't answered before (even if it was subsequently deleted
      $stream->write("=> /$oracle_space/question/$number/answer Answer this question\n");
    }
  }
  if ($question->{status} eq 'asked'
      and (not $fingerprint
	   or $fingerprint ne $question->{fingerprint})) {
    # if the question is being asked and you're not the question asker, list the
    # question but not the answers
    $stream->write("\n");
    $stream->write(encode_utf8 $question->{text});
    $stream->write("\n");
    # if you haven't answered the question, you may answer it; if you have
    # answered it, you may delete your answer
    if ($fingerprint) {
      my $n = 0;
      my $answered = 0;
      for my $answer (@{$question->{answers}}) {
	$n++;
	next unless $answer->{fingerprint} eq $fingerprint;
	$answered = 1;
	next unless $answer->{text};
	$answered = 2;
	$stream->write("\n");
	$stream->write("## Your answer\n");
	$stream->write(encode_utf8 $answer->{text});
	$stream->write("\n");
	$stream->write("=> /$oracle_space/question/$question->{number}/$n/delete Delete this answer\n");
	return 1;
      }
      if ($answered == 1) {
	$stream->write("\n");
	$stream->write("(Your answer was deleted.)\n");
	return 1;
      }
    }
  } else {
    $stream->write("\n");
    $stream->write(encode_utf8 $question->{text});
    $stream->write("\n");
    my $n = 0;
    for my $answer (@{$question->{answers}}) {
      $n++;
      next unless $answer->{text};
      $stream->write("\n");
      $stream->write("## Answer #$n\n");
      $stream->write(encode_utf8 $answer->{text});
      $stream->write("\n");
      if ($fingerprint
	  and ($fingerprint eq $question->{fingerprint}
	       or $fingerprint eq $answer->{fingerprint})) {
	$stream->write("=> /$oracle_space/question/$question->{number}/$n/delete Delete this answer\n");
      }
    }
  }
  return 1;
}

sub ask_question {
  my ($stream, $host, $text) = @_;
  my $fingerprint = $stream->handle->get_fingerprint();
  return result($stream, "60", "You need a client certificate to ask a question") unless $fingerprint;
  my $data = load_data($host);
  my $question = first { $_->{fingerprint} eq $fingerprint and $_->{status} ne 'published' } @$data;
  if ($question) {
    $log->info("Asking the oracle a question but there already is one asked question");
    success($stream);
    $stream->write("# Ask the oracle a question\n");
    $stream->write("You already have an unanswered question.\n");
    $stream->write("=> /$oracle_space/question/$question->{number} Show question\n");
  } elsif (not $text) {
    $log->info("Asking the oracle a question");
    result($stream, "10", "Your question for the oracle");
  } else {
    $log->info("Saving a new question for the oracle");
    $question = {
      date => strftime("%Y-%m-%d", gmtime),
      number => new_number($data),
      text => $text,
      fingerprint => $fingerprint,
      status => 'asked',
      answers => [],
    };
    unshift(@$data, $question);
    save_data($stream, $host, $data);
    success($stream);
    $stream->write("# The oracle accepts!\n");
    $stream->write("You question was submitted to the oracle.\n");
    $stream->write("=> /$oracle_space/question/$question->{number} Show question\n");
  }
  return 1;
}

sub answer_question {
  my ($stream, $host, $number, $text) = @_;
  my $fingerprint = $stream->handle->get_fingerprint();
  if (not $fingerprint) {
    $log->info("Answering a question requires a certificate");
    result($stream, "60", "You need a client certificate to answer a question");
    return 1;
  }
  my $data = load_data($host);
  my $question = first { $_->{number} eq $number } @$data;
  if (not $question) {
    $log->info("Answering a deleted question");
    success($stream);
    $stream->write("# Answer a question\n");
    $stream->write("The question you wanted to answer has been deleted.\n");
    $stream->write("=> /$oracle_space/ Back to the oracle\n");
    return 1;
  } elsif ($fingerprint eq $question->{fingerprint}) {
    $log->info("The question asker may not answer");
    result($stream, "40", "You may not answer your own question");
    return 1;
  }
  my $answer = first { $_->{fingerprint} eq $fingerprint } @{$question->{answers}};
  if ($answer) {
    $log->info("Answering a question again");
    success($stream);
    $stream->write("# Answer a question\n");
    $stream->write("You already answered this question.\n");
    $stream->write("=> /$oracle_space/question/$question->{number} Show\n");
  } elsif ($question->{status} ne 'asked') {
    $log->info("Answering an answered question");
    success($stream);
    $stream->write("# Answer a question\n");
    $stream->write("This question no longer takes answers.\n");
    $stream->write("=> /$oracle_space/question/$question->{number} Show\n");
  } elsif (not $text) {
    $log->info("Answering a question");
    result($stream, "10", "Your answer for the oracle");
  } else {
    $log->info("Saving a new answer for the oracle");
    $answer = {
      text => $text,
      fingerprint => $fingerprint,
    };
    push(@{$question->{answers}}, $answer);
    my $n = grep { $_->{text} } @{$question->{answers}};
    $question->{status} = 'answered' if $n >= $max_answers;
    save_data($stream, $host, $data);
    result($stream, "30", to_url($stream, $host, $oracle_space, "")) if $question->{status} eq 'answered';
    result($stream, "30", to_url($stream, $host, $oracle_space, "question/$question->{number}"));
  }
  return 1;
}

sub delete_answer {
  my ($stream, $host, $question_number, $answer_number) = @_;
  my $fingerprint = $stream->handle->get_fingerprint();
  if (not $fingerprint) {
    $log->info("Deleting an answer requires a certificate");
    result($stream, "60", "You need a client certificate to delete an answer");
    return 1;
  }
  my $data = load_data($host);
  my $question = first { $_->{number} eq $question_number } @$data;
  if (not $question) {
    $log->info("Deleting an answer of a deleted question");
    success($stream);
    $stream->write("# Delete an answer\n");
    $stream->write("The answer you wanted to answer belongs to a deleted question.\n");
    $stream->write("=> /$oracle_space/ Back to the oracle\n");
    return 1;
  }
  my $n = 0;
  my $answer;
  for (@{$question->{answers}}) {
    next unless ++$n eq $answer_number;
    $answer = $_;
    last;
  }
  if (not $answer) {
    $log->info("Deleting an answer that does not exist (@{$question->{answers}})");
    success($stream);
    $stream->write("# Delete an answer\n");
    $stream->write("The answer you wanted to delete does not exist.\n");
    $stream->write("=> /$oracle_space/question/$question->{number} Show\n");
    return 1;
  } elsif ($fingerprint ne $answer->{fingerprint}
	   and $fingerprint ne $question->{fingerprint}) {
    $log->info("Deleting an answer not your own");
    success($stream);
    $stream->write("# Delete an answer\n");
    $stream->write("The answer you wanted to delete belongs to somebody else.\n");
    $stream->write("Switch identity or pick a different client certificate if you think you are the owner of this question or this answer\n");
    $stream->write("=> /$oracle_space/question/$question->{number} Show\n");
    return 1;
  } elsif (not $answer->{text}) {
    $log->info("Deleting a deleted answer");
    result($stream, "30", to_url($stream, $host, $oracle_space, "question/$question->{number}"));
  }
  $log->info("Deleting an answer");
  $answer->{text} = undef;
  if ($question->{status} ne 'asked') {
    my $n = grep { $_->{text} } @{$question->{answers}};
    if (not $n) {
      # answered or published question with no answers gets deleted
      @$data = grep { $_->{number} ne $question->{number} } @$data;
      save_data($stream, $host, $data);
      $stream->write("=> /$oracle_space/ Back to the oracle\n");
      return 1;
    }
  }
  save_data($stream, $host, $data);
  result($stream, "30", to_url($stream, $host, $oracle_space, "question/$question->{number}"));
  return 1;
}

sub publish_question {
  my ($stream, $host, $number) = @_;
  my $fingerprint = $stream->handle->get_fingerprint();
  if (not $fingerprint) {
    $log->info("Publishing a question requires a certificate");
    result($stream, "60", "You need a client certificate to publish a question");
    return 1;
  }
  my $data = load_data($host);
  my $question = first { $_->{number} eq $number } @$data;
  if (not $question) {
    $log->info("Publishing a deleted question");
    success($stream);
    $stream->write("# Publish a question\n");
    $stream->write("The question you wanted to publish has been deleted.\n");
    $stream->write("=> /$oracle_space/ Back to the oracle\n");
    return 1;
  } elsif ($fingerprint ne $question->{fingerprint}) {
    $log->info("Only the question asker may publish");
    $stream->write("# Publish a question\n");
    $stream->write("You are not the owner of this question, which is why you cannot publish it.\n");
    $stream->write("Switch identity or pick a different client certificate if you think you are the owner of this question\n");
    $stream->write("=> /$oracle_space/ Back to the oracle\n");
    return 1;
  }
  $log->info("Publishing a question");
  $question->{status} = 'published';
  save_data($stream, $host, $data);
  result($stream, "30", to_url($stream, $host, $oracle_space, "question/$question->{number}"));
  return 1;
}

sub delete_question {
  my ($stream, $host, $number) = @_;
  my $fingerprint = $stream->handle->get_fingerprint();
  if (not $fingerprint) {
    $log->info("Deleting a question requires a certificate");
    result($stream, "60", "You need a client certificate to delete a question");
    return 1;
  }
  my $data = load_data($host);
  my $question = first { $_->{number} eq $number } @$data;
  if (not $question) {
    $log->info("Deleting a deleted question");
    result($stream, "30", to_url($stream, $host, $oracle_space, ""));
    return 1;
  } elsif ($fingerprint ne $question->{fingerprint}) {
    $log->info("Only the question asker may delete");
    success($stream);
    $stream->write("# Delete a question\n");
    $stream->write("You are not the owner of this question, which is why you cannot delete it.\n");
    $stream->write("Switch identity or pick a different client certificate if you think you are the owner of this question\n");
    $stream->write("=> /$oracle_space/question/$question->{number} Back to the question\n");
    return 1;
  }
  $log->info("Deleting a question");
  @$data = grep { $_->{number} ne $question->{number} } @$data;
  save_data($stream, $host, $data);
  result($stream, "30", to_url($stream, $host, $oracle_space, ""));
  return 1;
}

1;
