package BGPmon::CPM::Prefix;

use 5.010001;
use strict;
use warnings;
use base qw(BGPmon::CPM::DBObject);
use BGPmon::CPM::PrefixAuthoritativeForDomain;
use BGPmon::CPM::DomainResolvesToPrefix;
use BGPmon::CPM::PrefixToSearchPath;

our $VERSION = '1.03';

 
__PACKAGE__->meta->setup
(
 table => 'prefixes',
 columns => [ qw(dbid prefix watch_more_specifics watch_covering list_dbid) ],
 pk_columns => 'dbid',
 allow_inline_column_values => 1,
 foreign_keys =>
      [
        plist =>
        {
          relationship_type => 'many to one',
          class       => 'BGPmon::CPM::PList',
          key_columns => { list_dbid => 'dbid' },
        }
      ],
  relationships =>
      [
        authoritative_for =>
        {
          type      => 'many to many',
          map_class => 'BGPmon::CPM::PrefixAuthoritativeForDomain'
        },
        domains =>
        {
          type      => 'many to many',
          map_class => 'BGPmon::CPM::DomainResolvesToPrefix'
        },
        search_paths =>
        {
          type      => 'many to many',
          map_class => 'BGPmon::CPM::PrefixToSearchPath'
        } 
      ]

);
__PACKAGE__->meta->error_mode('return');

sub edit{
  my $self = shift;
  my $data = shift;

  foreach my $af (@{$data->{'authoritative_for'}}){
    $self->add_authoritative_for({domain=>$af->{'domain'}});
  }
  foreach my $d (@{$data->{'domains'}}){
    $self->add_domains({domain=>$d->{'domain'}});
  }
  foreach my $sp (@{$data->{'search_paths'}}){
    $self->add_search_paths({path=>$sp->{'path'}});
                             #param_prefix=>$sp->{'param_prefix'}});
  }
  $self->save;
}

 

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

BGPmon::CPM::PList - Perl extension for blah blah blah

=head1 SYNOPSIS

  use BGPmon::CPM::PList;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for BGPmon::CPM::PList, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>bgpmoner@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
