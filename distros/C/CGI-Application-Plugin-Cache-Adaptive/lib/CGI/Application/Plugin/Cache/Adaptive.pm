package CGI::Application::Plugin::Cache::Adaptive;

use strict;
use warnings;

use base qw(Exporter);
use Attribute::Handlers;
use Cache::Adaptive;
use Carp qw(croak);
use Class::Inspector;
use Storable qw(freeze);

our @EXPORT = qw(&cache_adaptive);

=head1 NAME

CGI::Application::Plugin::Cache::Adaptive - Provide cacheable to method using attribute.

=head1 VERSION

version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  package MyApp;
  use base qw(CGI::Application);
  use CGI::Application::Plugin::Cache::Adaptive;
  
  use Cache::FileCache;
  
  sub setup {
    my $self = shift;

    $self->start_mode('default');
    $self->run_modes(
        'default' => 'do_default'
    );
  
    $self->cache_adaptive({
        backend => Cache::FileCache->new({
            namespace => 'html_cache',
            max_size  => 10 * 1024 * 1024,
        }),
        expires_min => 3,
        expires_max => 60,
        check_load  => sub {
            my $entry = shift;
            int($entry->{process_time} * 2) - 1;
        },
    });
  }
  
  sub do_default : Cacheable(qw/path path_info query/) {
    sleep 10;
    return "test";
  }

=head1 DESCRIPTION

This module provides adaptive cache to specified method by 'Cacheable' attribute.
Cache mechanism depends on L<Cache::Adaptive>.

=head1 USAGE

=head2 Cacheable attribute

Cacheable attribute is able to accept some arguments.
The arguments effects L<Cache::Adaptive> behavior.

The arguments must be array or hash reference.
See below the arguments detail.

=over 4

=item Array arguments

Example,

    sub do_something : Cacheable(qw/path session/) {
        # process by user
    }

Array arguments accepts 4 items,

=over 4

=item path

Add path(script_name) to cache key salt.

=item query

Add query string to cache key salt.

=item path_info

Add path_info to cache key salt.

=item session

Add session_id to cache key salt.

=back

=item Hash reference arguments

Example,

    sub do_something : Cacheable({key_from => [qw/path path_info/], label => 'memcached'}) {
        # some process
    }

Hash reference accepts 2 original key and any key permitted by L<Cache::Adaptive>'s access method.

=over 4

=item key_from

Same as array arguments. See L<CGI::Application::Plugin::Cache::Adaptive/Array arguments>.

=item label

Change cache profile to specified labeled cache object.
See L<Cache::Adaptive/cache_adaptive($label)>.

=back

=back

=head1 METHODS

=head2 cache_adaptive()

Alias cache_adaptive('default'). 
See L<CGI::Application::Plugin::Cache::Adaptive/cache_adaptive($label)>

=head2 cache_adaptive($label)

Get L<Cache::Adaptive> object by label.

=head2 cache_adaptive($hash_ref)

Set L<Cache::Adaptive> object to 'default' label.
The $hash_ref is L<Cache::Adaptive>'s new parameter.

=head2 cache_adaptive($cache_obj)

Set L<Cache::Adaptive> or that inheritance object to 'default' label.

=head2 cache_adaptive($label, $hash_ref)

Set L<Cache::Adaptive> object to specified label.
The $hash_ref is L<Cache::Adaptive>'s new parameter.

=head2 cache_adaptive($label, $cache_obj)

Set L<Cache::Adaptive> or that inheritance object to specified label.

=cut

sub cache_adaptive {
    my $self = shift;

    if (@_ == 2) {
        if (UNIVERSAL::isa($_[1], 'Cache::Adaptive')) {
            $self->{'Cache::Adaptive::cache_adaptive'}{$_[0]} = $_[1];
        }
        else {
            $self->{'Cache::Adaptive::cache_adaptive'}{$_[0]} = Cache::Adaptive->new($_[1]);
        }
    }
    elsif (@_ == 1) {
        if (UNIVERSAL::isa($_[0], 'Cache::Adaptive')) {
            return $self->{'Cache::Adaptive::cache_adaptive'}{'default'} = $_[0];
        }
        elsif (ref $_[0] eq 'HASH') {
            $self->{'Cache::Adaptive::cache_adaptive'}{'default'} = Cache::Adaptive->new($_[0]);
        }
        else {
            return $self->{'Cache::Adaptive::cache_adaptive'}{$_[0]};
        }
    }
    else {
        return $self->{'Cache::Adaptive::cache_adaptive'}{'default'};
    }
}

=head2 CGI::Application::Cacheable()

Provide cacheable to specified method.
See L<Attribute::Handlers>

=cut

sub CGI::Application::Cacheable : ATTR(CODE,BEGIN) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;

    my %key_index = (
        'path' => 0,
        'query' => 1,
        'path_info' => 2,
        'session' => 3
    );

    $package->add_callback('init',
        sub {
            my $self = shift;

            ### In the next process, runmode will be rededined.
            ### In CAP::AutoRunmode, it was cached code reference before redefined.
            ### Therefore now start_mode and error_mode must be static value.
            if (Class::Inspector->loaded('CGI::Application::Plugin::AutoRunmode')) {
                $self->start_mode;
                $self->error_mode;
            }
        }
    );

    $package->add_callback('init', 
        sub {
            my ($self, @args) = @_;

            $data = {} unless ($data);
            my $data_type = ref $data;

            if ($data_type eq 'ARRAY' || $data_type eq 'HASH') {
                my $label = ($data_type eq 'HASH') ? delete $data->{label} || 'default' : 'default';
                my $key_from = ($data_type eq 'HASH') ? delete $data->{key_from} : $data;
                $key_from = [qw(path)] if (!$key_from || @$key_from == 0);

                my %extra_params = ($data_type eq 'HASH') ? %$data : ();

                my $method = (grep { $package->can($_) == $referent } @{Class::Inspector->methods($package)})[0];
                return unless ($method);

                {
                    no strict 'refs';
                    no warnings 'redefine';

                    *{$package . "::" . $method} = sub {
                        my ($self, @args) = @_;

                        local $CGI::USE_PARAM_SEMICOLONS = 0;
                        my @key_array = (undef, undef, undef, undef);

                        for my $key (grep { exists $key_index{$_} } @$key_from) {
                            my $value = undef;

                            $value = $self->query->script_name if ($key eq 'path');
                            $value = $self->query->query_string if ($key eq 'query');
                            $value = $self->query->path_info if ($key eq 'path_info');
                            $value = ($self->can('session')) ? $self->session->id : undef if ($key eq 'session');

                            $key_array[$key_index{$key}] = $value if (exists $key_index{$key} && defined $value);
                        }

#                        {
#                            my %debug = ();
#                            $debug{$_} = $key_array[$key_index{$_}] for (keys %key_index);
#
#                            $self->cache_adaptive($label)->log->(\%debug);
#                        }

                        return $self->cache_adaptive($label)->access({
                            key => freeze(\@key_array),
                            builder => sub {
                                return $referent->($self, @args);
                            },
                            %extra_params
                        });
                    };

                    ### If using CAP::AutoRunmode, it's code reference cache table must be refleshed.
                    if (Class::Inspector->loaded('CGI::Application::Plugin::AutoRunmode')) {
                        if (exists $CGI::Application::Plugin::AutoRunmode::RUNMODES{"$referent"}) {
                            delete $CGI::Application::Plugin::AutoRunmode::RUNMODES{"$referent"};
                            $CGI::Application::Plugin::AutoRunmode::RUNMODES{$package->can($method)} = 1;
                        }
                    }
                }
            }
        }
    );
}

=head1 SEE ALSO

=over 4

=item L<Cache::Adaptive>

=item L<CGI::Application>

=item L<CGI::Application::Plugin::AutoRunmode>

=item L<Attribute::Handlers>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 THANKS

Kazuho Oku, C<< <kazuhooku@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-cache-adaptive@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CGI::Application::Plugin::Cache::Adaptive
