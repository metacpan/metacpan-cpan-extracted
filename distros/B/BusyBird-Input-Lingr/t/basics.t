use strict;
use warnings;
use Test::More;
use Test::Deep 0.084 qw(cmp_deeply superhashof);
use BusyBird::Input::Lingr;

sub sh { superhashof({@_}) }

sub message {
    my ($id, $timestamp, $speaker_id, $nickname) = @_;
    $speaker_id ||= "toshioito";
    $nickname ||= "Toshio Ito";
    return {
        id => $id,
        timestamp => $timestamp,
        room => 'sample_room',
        public_session_id => 'hogehoge',
        icon_url => 'http://hoge.com/avatar.png',
        type => 'user',
        speaker_id => $speaker_id,
        nickname => $nickname,
        text => "ID: $id",
        local_id => undef,
    };
}


{
    note('--- default setting');
    my $input = BusyBird::Input::Lingr->new;
    my $got = $input->convert(message(10, '2014-05-21T05:23:33Z'));
    cmp_deeply $got, sh(
        id => 'http://lingr.com/room/sample_room/archives/2014/05/21#message-10',
        created_at => 'Wed May 21 05:23:33 +0000 2014',
        user => sh(
            screen_name => 'toshioito',
            name => 'Toshio Ito',
            profile_image_url => 'http://hoge.com/avatar.png'
        ),
        text => "ID: 10",
        busybird => sh(
            status_permalink => 'http://lingr.com/room/sample_room/archives/2014/05/21#message-10'
        )
    ), "default setting OK";
}

{
    my $api_base = "http://other.lingr.org/api";
    my $exp_base = "http://other.lingr.org";
    my $input = BusyBird::Input::Lingr->new(api_base => $api_base);
    my @testcases = (
        { label => "empty", input => [], exp => [] },
        { label => "single", input => [ message(143, '2014-07-24T22:12:00Z') ],
          exp => [sh(
              id => "$exp_base/room/sample_room/archives/2014/07/24#message-143",
              created_at => "Thu Jul 24 22:12:00 +0000 2014",
              user => sh(
                  screen_name => "toshioito",
                  name => 'Toshio Ito',
                  profile_image_url => 'http://hoge.com/avatar.png',
              ),
              text => "ID: 143",
              busybird => sh( status_permalink => "$exp_base/room/sample_room/archives/2014/07/24#message-143" )
          )]},
        { label => "two", input => [message(200, '2014-07-07T10:00:03Z'), message(300, '2014-07-07T10:11:34Z', 't-ito', 'TITO')],
          exp => [
              sh(
                  id => "$exp_base/room/sample_room/archives/2014/07/07#message-200",
                  created_at => "Mon Jul 07 10:00:03 +0000 2014",
                  user => sh(
                      screen_name => "toshioito",
                      name => 'Toshio Ito',
                      profile_image_url => 'http://hoge.com/avatar.png',
                  ),
                  text => "ID: 200",
                  busybird => sh( status_permalink => "$exp_base/room/sample_room/archives/2014/07/07#message-200" )
              ),
              sh(
                  id => "$exp_base/room/sample_room/archives/2014/07/07#message-300",
                  created_at => "Mon Jul 07 10:11:34 +0000 2014",
                  user => sh(
                      screen_name => "t-ito",
                      name => 'TITO',
                      profile_image_url => 'http://hoge.com/avatar.png',
                  ),
                  text => "ID: 300",
                  busybird => sh( status_permalink => "$exp_base/room/sample_room/archives/2014/07/07#message-300" )
              ),
          ]}
    );
    foreach my $case (@testcases) {
        my $label = $case->{label};
        my @got_list = $input->convert(@{$case->{input}});
        cmp_deeply \@got_list, $case->{exp}, "$label: list result OK";

        my $got_scalar = $input->convert(@{$case->{input}});
        is_deeply $got_scalar, $got_list[0], "$label: scalar result OK";
    }
}

done_testing;

