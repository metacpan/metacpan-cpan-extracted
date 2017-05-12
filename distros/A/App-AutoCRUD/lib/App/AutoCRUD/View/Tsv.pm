package App::AutoCRUD::View::Tsv;

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::View';
use Encode qw/encode/;

use namespace::clean -except => 'meta';

sub render {
  my ($self, $data, $context) = @_;

  # ordered column names from colgroups
  my @headers;
  foreach my $colgroup (@{$data->{colgroups}}) {
    my $cols = $colgroup->{columns};
    push @headers, map {$_->{COLUMN_NAME}} @$cols;
  }

  # assemble header row and data rows
  no warnings 'uninitialized';
  my $str = join("\n", join("\t", @headers),
                       map {join("\t", @{$_}{@headers})} @{$data->{rows}});

  # return Plack response
  return [200, ['Content-type' => 'text/tab-separated-values; charset=utf-16'], 
               [encode("utf16", $str)] ];
}


1;


__END__



=head1 NAME

App::AutoCRUD::View::Tsv - View for tab-separated values

=head1 DESCRIPTION

This view outputs data as a file with tab-separated values,
encoded in UTF-16 so that Excel can read wide characters correctly.


