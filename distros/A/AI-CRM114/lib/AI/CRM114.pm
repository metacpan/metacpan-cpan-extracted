package AI::CRM114;

use 5.008000;
use strict;
use warnings;
use IPC::Run qw /run/;

our @ISA = qw();

our $VERSION = '0.01';

sub new {
  my $class = shift;
  my $self = { cmd => 'crm', @_ };
  bless $self, $class;
  return $self;
}

sub classify {
  my ($self, $flags, $files, $text) = @_;

  my $code = qq#-{
    isolate (:stats:);
    classify <@$flags> ( @$files ) (:stats:);
    output /:*:stats:/
  }#;

  my $o = "";
  my $h = run [$self->{cmd}, $code], \$text, \$o;

  my ($file, $prob, $pr) = $o =~
    /Best match to file \S+ \((.*?)\) +prob: *([0-9.]+) +pR: *([0-9.-]+)/;

  wantarray ? ($file, $prob, $pr) : $file;
}

sub learn {
  my ($self, $flags, $file, $text) = @_;

  my $code = qq#-{ learn <@$flags> ( $file ) }#;

  my $o = "";
  my $h = run [$self->{cmd}, $code], \$text, \$o;
}

1;

__END__

=head1 NAME

AI::CRM114 - Wrapper for the statistical data classifier CRM114

=head1 SYNOPSIS

  use AI::CRM114;
  my $crm = AI::CRM114->new(cmd => '/path/to/crm');

  # Learn new text
  $crm->learn(['osb'], 'spam.css', 'MAKE MONEY FAST');

  # Classify some text
  my $class = $crm->classify(['osb'], ['a.css', 'b.css'], $text);

=head1 DESCRIPTION

The CRM114 Discriminator, is a collection of tools to classify data,
e.g. for use in spam filters. This module is a simple wrapper around
the command line executable. Feedback is very welcome, the interface
is unstable. Use with caution.

=head1 METHODS

=over 

=item AI::CRM114->new(%options)

Creates a new instance of this class. The following options are
available:

=over

=item cmd => '/path/to/crm'

Specifies the path to the crm executable.

=back

=item $crm->learn(\@flags, $file, $text)

Learn that the text belongs to the file using the specified flags.
Permissable flags are specified in the C<QUICKREF.txt> file that
comes with CRM114. Examples include C<winnow>, C<microgroom>, and
C<osbf>.

=item classify(\@flags, \@files, $text)

Attempt to correlate the text to one of the files using the
specified flags. Permissable flags are specified in the C<QUICKREF.txt>
file that comes with CRM114. Examples include C<unique>, C<fscm>, and
C<svm>.

In scalar context, returns the path of the best matching file.
In list context, returns a list containing the path of the best file,
and the probability and pR values as reported in C<(:stats:)>.

=back

=head1 SEE ALSO

  * http://crm114.sourceforge.net/
  * http://crm114.sourceforge.net/docs/QUICKREF.txt

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2009 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut