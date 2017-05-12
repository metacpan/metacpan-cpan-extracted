package App::AquariumHive::Plugin::Cron;
BEGIN {
  $App::AquariumHive::Plugin::Cron::AUTHORITY = 'cpan:GETTY';
}
$App::AquariumHive::Plugin::Cron::VERSION = '0.003';
use Moo;
use App::AquariumHive::Tile;
use JSON::MaybeXS;

with qw(
  App::AquariumHive::Role
);

sub BUILD {
  my ( $self ) = @_;

  $self->add_tile( 'cron' => App::AquariumHive::Tile->new(
    id => 'cron',
    bgcolor => 'blue',
    content => <<"__HTML__",

<h1 class="text-center">
 <i class="icon-chronometer"></i>
</h1>

__HTML__
        js => <<"__JS__",

\$('#cron').click(function(){
  call_app('cron');
});

__JS__
  ));

  $self->web_mount( 'cron', sub {
    return [ 200, [ "Content-Type" => "application/json" ], [encode_json({
      html => <<__HTML__,
  <h1 class="text-center">Ablauf Management</h1>
  <hr/>

__HTML__
    })] ];
  });

}

1;

__END__

=pod

=head1 NAME

App::AquariumHive::Plugin::Cron

=head1 VERSION

version 0.003

=head1 DESCRIPTION

B<IN DEVELOPMENT, DO NOT USE YET>

See L<http://aquariumhive.com/> for now.

=head1 SUPPORT

IRC

  Join #AquariumHive on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  https://github.com/homehivelab/aquariumhive
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/homehivelab/aquariumhive/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
