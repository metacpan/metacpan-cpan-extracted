#!/usr/local/bin/perl5.10.0

use Web::Simple 'Bot::BasicBot::Pluggable::Module::Notes::App';
{
    package Bot::BasicBot::Pluggable::Module::Notes::App;

    use lib '/usr/src/perl/Bot-BasicBot-Pluggable-Module-Notes/lib';
    use Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite;
    use File::Spec::Functions;
    use JSON ();

    my $store =  Bot::BasicBot::Pluggable::Module::Notes::Store::SQLite
    ->new( "/home/castaway/public_html/notesbot/brane.db" );


    default_config ( file_dir => q{/usr/src/perl/Bot-BasicBot-Pluggable-Module-Notes/root/},
#                     dsn => '/home/castaway/public_html/notesbot/brane.db'
                   );

    sub static_file {
        my ($self, $file, $type) = @_;
        open my $fh, '<', catfile($self->config->{file_dir}, "$file") or return [ 404, [ 'Content-type', 'text/html' ], [ 'file not found']];

        local $/ = undef;
        my $file_content = <$fh>;
        close $fh or return [ 500, [ 'Content-type', 'text/html' ], [ 'Internal Server Error'] ];

        return [ 200, [ 'Content-type' => $type ], [ $file_content ] ];
 
    }

    sub notes_json {
        my ($self, %params) = @_;
#        my @checkedparams{ qw(date time channel name notes) } = @{$params->{qw(date time channel name notes)}};

        ## arrayref of hashrefs
        # id, date, time, channel, name, notes
        # extract date/time fields
        my $db_notes = $store->get_notes(%params);

        warn Data::Dumper::Dumper($db_notes);
        my $rows = [ map { {
            id => $_->{id},
            cell => [ @{$_}{qw/id date time channel name notes/} ]
        }
                       } @$db_notes ];
        my $notes = {
                     total => 1,
                     page => 1,
                     records => scalar @$db_notes,
                     rows => $rows,
                    };

        return [ 200, [ 'Content-type' => 'application/json' ], [ JSON::encode_json($notes) ] ];
    }

    dispatch {
        sub (/) {
            return $self->static_file('index.html')
        },
        sub (/js/**) {
            my $file=$_[1];
            return $self->static_file("js/$file", "text/javascript");
        },
        sub (/css/**) {
            my $file=$_[1];
            return $self->static_file("css/$file", "text/css");
        },
#        sub (/json + ?:date~&:time~&:channel~&:name~&:notes~) {
          ## Add page and rows args.
        sub (/json + ?id~&date~&time~&channel~&name~&notes~&page=&rows=&sidx=&sord=) {
#            my ($self, $params) = @_;
            my ($self, $id, $date, $time, $channel, $name, $notes, $page, $rows, $order_ind, $sort_order) = @_;
            return $self->notes_json(id => $id,
                                     date => $date,
                                     time => $time,
                                     channel => $channel,
                                     name => $name,
                                     notes => $notes,
                                     page => $page,
                                     rows => $rows, 
                                     order_ind => $order_ind,
                                     sort_order => $sort_order,
                                    );
        }

    };

}

Bot::BasicBot::Pluggable::Module::Notes::App->run_if_script;
