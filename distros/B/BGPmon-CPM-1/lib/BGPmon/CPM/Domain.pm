package BGPmon::CPM::Domain;

use 5.010001;
use strict;
use warnings;
use base qw(BGPmon::CPM::DBObject);
use BGPmon::CPM::Prefix;

our $VERSION = '1.03';

 
__PACKAGE__->meta->setup
(
 table => 'domains',
 columns => [ qw(dbid domain) ],
 pk_columns => 'dbid',
 unique_key => 'domain',
 relationships =>
    [
      authorities =>{
          type       => 'many to many',
          map_class  => 'BGPmon::CPM::PrefixAuthoritativeForDomain',
        },
      resolves_to =>{
          type       => 'many to many',
          map_class  => 'BGPmon::CPM::DomainResolvesToPrefix'
      }
    ],

);
__PACKAGE__->meta->error_mode('return');
 

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

BGPmon::CPM::Domain - Perl extension for blah blah blah

=head1 SYNOPSIS

  use BGPmon::CPM::Domain;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for BGPmon::CPM::Domain, created by h2xs. It looks like the
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
