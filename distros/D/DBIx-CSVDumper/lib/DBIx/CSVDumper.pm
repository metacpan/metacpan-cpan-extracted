package DBIx::CSVDumper;
use strict;
use warnings;
use utf8;
use Encode;
use Text::CSV;

our $VERSION = '0.02';

our %DEFAULT_CSV_ARGS = (
    binary          => 1,
    always_quote    => 1,
    eol             => "\r\n",
);

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub csv_obj {
    my ($self, $obj) = @_;
    $self->{_csv_obj} = $obj if $obj;
    $self->{_csv_obj} ||= Text::CSV->new({
        %DEFAULT_CSV_ARGS,
        %{ $self->{csv_args} || {} },
    });
}

sub encoding {
    my ($self, $enc) = @_;
    $self->{_encoding} = Encode::find_encoding($enc) if $enc;
    $self->{_encoding} ||= Encode::find_encoding($self->{encoding} || 'utf-8');
}

sub dump {
    my ($self, %args) = @_;
    my $sth      = $args{sth};
    my $file     = $args{file};
    my $fh       = $args{fh};
    my $encoding = $args{encoding} || $self->encoding;

    $sth->execute if $DBI::VERSION >= 1.41 && !$sth->{Executed};

    unless ($fh) {
        open $fh, '>', $file or die $!;
    }

    my $csv = $self->csv_obj;
    my $cols = $sth->{NAME};
    $csv->print($fh, $cols);
    while (my @data = $sth->fetchrow_array) {
        @data = map {encode($encoding => $_)} @data;
        $csv->print($fh, [@data]);
    }
}

1;
__END__

=head1 NAME

DBIx::CSVDumper - dumping database (DBI) data into a CSV.

=head1 SYNOPSIS

  use DBIx::CSVDumper;
  my $dbh = DBI->connect(...);
  my $dumper = DBIx::CSVDumper->new(
    csv_args  => {
      binary          => 1,
      always_quote    => 1,
      eol             => "\r\n",
    },
    encoding    => 'utf-8',
  );
  
  my $sth = $dbh->prepare('SELECT * FROM item');
  $sth->execute;
  $dumper->dump(
    sth     => $sth,
    file    => 'tmp/hoge.csv',
  );

=head1 DESCRIPTION

DBIx::CSVDumper is a module for dumping database (DBI) data into a CSV.

=head1 CONSTRUCTOR

=over

=item C<new>

  my $dumper = DBIx::CSVDumper->new(%args);

Create new dumper object. C<%args> is a hash with object parameters.
Currently recognized keys are:

=item C<csv_args>

  csv_args => {
    binary          => 1,
    always_quote    => 1,
    eol             => "\r\n",
  },
  (default: same as above)

=item C<encoding>

  encoding => 'cp932',
  (default: utf-8)

=back

=head1 METHOD

=over

=item C<dump>

  $dumper->dump(%args);

Dump CSV file. C<%args> is a hash with parameters. Currently recognized
keys are:

=item C<sth>

  sth => $sth
  (required)

the value is a C<DBI::st> object. C<execute> method should be called beforehand or
automatically called with DBI 1.41 or newer and no bind parameters.

=item C<file>

  file => $file

string of file name.

=item C<fh>

  fh => $fh

file handle. args C<file> or C<fh> is required.

=item C<encoding>

  enocding => 'euc-jp',
  (default: $dumper->encoding)

encoding.

=item C<csv_obj>

=item C<encoding>

=back

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
