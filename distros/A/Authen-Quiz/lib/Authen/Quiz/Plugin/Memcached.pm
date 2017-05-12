package Authen::Quiz::Plugin::Memcached;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Memcached.pm 361 2008-08-18 18:29:46Z lushe $
#
use strict;
use warnings;

eval{ require Cache::Memcached::Fast };  ## no critic.
if (my $error= $@) {
	$error=~m{Can\'t\s+locate\s+Cache.+?Memcached.+?Fast}i || die $error;
	require Cache::Memcached;
	*cache= sub { $_[0]->{_cache} ||= Cache::Memcached->new($_[0]->{memcached}) };
} else {
	*cache= sub { $_[0]->{_cache} ||= Cache::Memcached::Fast->new($_[0]->{memcached}) };
}

our $VERSION= '0.01';

our $CacheKey= 'authen_quiz_plugin_memcached';

sub new {
	my $self= shift->next::method(@_);
	my $c= $self->{memcached} ||= {};
	   $c->{servers} ||= ["127.0.0.1:11211"];
	$self->{memcached_expire} ||= 600;
	$self;
}
sub load_quiz {
	my($self)= @_;
	no warnings qw/ once /;
	my $key= "${CacheKey}_$Authen::Quiz::QuizYaml";
	$self->cache->get($key) || do {
		my $data= $self->next::method;
		$self->cache->set($key=> $data, $self->{memcached_expire});
		$data;
	  };
}

1;

__END__

=head1 NAME

Authen::Quiz::Plugin::Memcached - Plugin to which problem data of Authen::Quiz is cached.

=head1 SYNOPSIS

  use Authen::Quiz::FW qw/ Memcached /;
  
  my $q= Authen::Quiz::FW->new(
    data_folder => '/path/to/authen_quiz',
    memcached   => {
      servers=> ["127.0.0.1:11211"],
      },
    memcached_expire => 600,
    );

=head1 DESCRIPTION

I think that it comes to influence the response when the problem data of L<Authen::Quiz>
is enlarged. This plugin caches the problem data with Memcached, and prevents the
response from deteriorating.

The option of Memcached is passed to the constructor reading by way of
L<Authen::Quiz::FW> to use it.

Besides, the item named memcached_expire that sets the expiration date of cache
can be passed. Default is 600.

When load_quiz is called by this, cache comes to be effective.

=head1 METHODS

=head2 new

Constructor.

=head2 load_quiz

The method of L<Authen::Quiz> is Obarraited and cache is effective.

=head2 cache

The cashe object is returned.

=head1 SEE ALSO

L<Authen::Quiz>,
L<Authen::Quiz::FW>,
L<Cache::Memcached>,
L<Cache::Memcached::Fast>,

L<http://egg.bomcity.com/wiki?Authen%3a%3aQuiz>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
