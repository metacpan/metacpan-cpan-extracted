package Bot::Cobalt::Frontend::Utils;
$Bot::Cobalt::Frontend::Utils::VERSION = '0.021003';
use v5.10;
use strictures 2;

use Carp;

use parent 'Exporter::Tiny';

our @EXPORT_OK = qw/
  ask_yesno
  ask_question
/;
our %EXPORT_TAGS;
{ my %s; push @{$EXPORT_TAGS{all}}, grep {!$s{$_}++} @EXPORT_OK }


sub ask_question {
  my %args = @_;

  my $question = delete $args{prompt} || croak "No prompt => specified";
  my $default  = delete $args{default};

  my $validate_sub;
  if (defined $args{validate}) {
    $validate_sub = ref $args{validate} eq 'CODE' ?
        delete $args{validate}
        : croak "validate => should be a coderef";
  }

  select(STDOUT); $|++;

  my $print_and_grab = sub {
    print "$question ", defined $default ? "[$default] " : "> ";
    my $ret = <STDIN>;  chomp($ret);
    $ret = $default if defined $default and $ret eq '';
    $ret
  };

  my $input = $print_and_grab->();
  until (length $input) {
    print "No input specified.\n";
    $input = $print_and_grab->()
  }

  VALID: {
    if ($validate_sub) {
      my $invalid = $validate_sub->($input);
      last VALID unless defined $invalid;
      die "Invalid input; $invalid\n"
        if $args{die_if_invalid} or $args{die_unless_valid};
      until (not defined $invalid) {
        print "Invalid input; $invalid\n";
        $print_and_grab->();
        redo VALID
      }
    }
  }

  return $input
}

sub ask_yesno {
  my %args = @_;
  my $question = $args{prompt} || croak "No prompt => specified";

  my $default  = lc(
    substr($args{default}||'', 0, 1) || croak "No default => specified"
  );

  croak "default should be Y or N"
    unless $default =~ /^[yn]$/;

  my $yn = $default eq 'y' ? 'Y/n' : 'y/N' ;

  select(STDOUT); $|++;

  my $input;
  my $print_and_grab = sub {
    print "$question  [$yn] ";
    $input = <STDIN>;  chomp($input);
    $input = $default if $input eq '';
    lc substr $input eq '' ? $default : $input, 0, 1
  };
  $print_and_grab->();
  until ($input && $input eq 'y' || $input eq 'n') {
    print "Invalid input; should be either Y or N\n";
    $print_and_grab->();
  }

  $input eq 'y' ? 1 : 0
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Frontend::Utils - Helper utils for Bot::Cobalt frontends

=head1 SYNOPSIS

  use Bot::Cobalt::Frontend::Utils qw/ :all /;

  my $do_something = ask_yesno(
    prompt  => "Do some stuff?"
    default => 'y',
  );

  if ($do_something) {
    ## Yes
  } else {
    ## No
  }

  ## Ask a question with a default answer
  ## Keep asking until validate => returns undef
  my $answer = ask_question(
    prompt  => "Tastiest snack?"
    default => "cake",
    validate => sub {
      my ($value) = @_;
      return "No value specified" unless defined $value;
      (grep { $_ eq $value } qw/cake pie cheese/) ?
        undef : "Snack options are cake, pie, cheese"
    },
  );

=head1 DESCRIPTION

This module exports simple helper functions for use by L<Bot::Cobalt>
frontends.

The exported functions are fairly simplistic; take a gander at
L<Term::UI> if you're looking for a rather more solid terminal/user 
interaction module.

=head1 EXPORTED

=head2 ask_yesno

Prompt the user for a yes or no answer.

A default 'y' or 'n' answer must be specified:

  my $yesno = ask_yesno(
    prompt  => "Do stuff?"
    default => "n"
  );

Returns false on a "no" answer, true on a "yes."

=head2 ask_question

Prompt the user with a question, possibly with a default answer, and 
optionally with a code reference to validate.

  my $ans = ask_question(
    prompt  => "Color of the sky?"
    default => "blue",
    validate => sub {
      my ($value) = @_;

      return "No value specified" unless defined $value;

      return undef if grep { $_ eq $value } qw/blue pink orange red/;

      return "Valid colors: blue, pink, orange, red"
    },
    die_if_invalid => 0,
  );

If a validation coderef is specified, it should return undef to signify 
successful validation or an error string describing the problem.

If B<die_if_invalid> is specified, an invalid answer will die() 
out rather than asking again.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
