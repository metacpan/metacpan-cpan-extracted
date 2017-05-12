package Beagle::Web::Router;
use Beagle::Web;
use Beagle::Util;
use Lingua::EN::Inflect 'A';
use Beagle::Web::Form;
use Beagle::Web::Router::Util;
use List::MoreUtils 'first_index';

get '/' => sub {
    render 'index', entries => handle()->entries;
};

get '/fragment/menu' => sub {
    render 'menu';
};

get '/fragment/entry/:id' => sub {
    my %vars = @_;
    my $i    = $vars{id};
    my @ret  = resolve_id( $i, handle => handle() );
    return unless @ret == 1;

    render 'entry', entry => $ret[0]->{entry};
};

get '/fragment/tag/:tag' => sub {
    my %vars = @_;
    my $tag = decode_utf8 $vars{tag};
    my $entries = Beagle::Web->tags( handle() )->{$tag} || [];
    render '_list', entries => $entries, disable_page => 1;
};

get '/fragment/archive/{year:[0-9]+}' => sub {
    my %vars = @_;
    my $year = $vars{year};
    render '_list',
      entries => [
        map { @{ Beagle::Web->archives( handle() )->{$year}{$_} } }
          keys %{ Beagle::Web->archives( handle() )->{$year} || {} }
      ],
      disable_page => 1;
};

get '/fragment/archive/{year:[0-9]+}/{month:[0-9]{2}}' => sub {
    my %vars = @_;
    my $year = $vars{year};
    my $month = $vars{month};
    my $entries = Beagle::Web->archives( handle() )->{$year}{$month} || [];
    render '_list', entries => $entries, disable_page => 1;
};

get '/tag/:tag' => sub {
    my %vars = @_;
    my $tag  = decode_utf8 $vars{tag};

    return redirect '/'
      unless $tag && Beagle::Web->tags( handle() )->{$tag};

    render 'index',
      "tag_$tag"   => 1,
      title        => "tag $tag",
      entries      => Beagle::Web->tags( handle() )->{$tag},
      prefix       => prefix() || '../';
};

get '/tags' => sub {
    render 'tags', title => 'tags';
};

get '/archives' => sub {
    render 'archives', title => 'archives';
};

get '/archive/{year:[0-9]+}' => sub {
    my %vars = @_;
    my $year = $vars{year};
    return redirect '/'
      unless $year && Beagle::Web->archives( handle() )->{$year};
    render 'index',
      entries => [
        map { @{ Beagle::Web->archives( handle() )->{$year}{$_} } }
          keys %{ Beagle::Web->archives( handle() )->{$year} || {} }
      ],
      title        => "in $year",
      prefix       => prefix() || '../';
};

get '/archive/{year:[0-9]+}/{month:[0-9]{2}}' => sub {
    my %vars  = @_;
    my $year  = $vars{year};
    my $month = $vars{month};
    return redirect '/'
      unless Beagle::Web->archives( handle() )->{$year}{$month};
    render 'index',
      entries => Beagle::Web->archives( handle() )->{$year}{$month},
      title  => "in $year/$month",
      prefix => prefix() || '../../';
};

get '/entry/:id' => sub {
    my %vars = @_;
    my $i    = $vars{id};
    my @ret  = resolve_id( $i, handle => handle() );
    return redirect "/" unless @ret == 1;
    my $id = $ret[0]->{id};
    return redirect "/entry/$id" unless $i eq $id;

    my $entry = $ret[0]->{entry};

    if ( $entry->type eq 'comment' ) {
        return
            redirect '/entry/'
          . $entry->parent_id . '#'
          . $entry->id;
    }

    my $index = first_index { $_->id eq $entry->id } @{handle()->entries};
    my %opt;
    if ( $index != 0 ) {
       $opt{next_entry} = handle()->entries->[$index-1];
    }

    if ( $index != @{ handle()->entries } - 1 ) {
        $opt{previous_entry} = handle()->entries->[ $index + 1 ];
    }

    render 'entry_single',
      entry        => $entry,
      prefix       => prefix() || '../',
      title        => $entry->summary(20),
      %opt;
};

get '/about' => sub {
    render 'about', title => 'about';
};

get '/feed' => sub { Beagle::Web->feed()->to_string };

any '/search' => sub {
    my $query = request()->param('query');
    return render 'search', title => 'search', search_only => 1 unless $query;

    my @found;
    for my $entry ( @{ handle()->entries } ) {
        push @found, $entry if $entry->serialize =~ /\Q$query/i;
    }

    @found = sort { $b->updated <=> $a->updated } @found;

    if ( @found == 1 ) {
        return redirect '/entry/' . $found[0]->id;
    }
    else {
        render 'search',
          search       => 1,
          title        => 'search',
          entries      => \@found,
          query        => $query,
          results_only => request()->param('results_only') ? 1 : 0;
    }
};

get '/admin/entries' => sub {
    render 'admin/entries',
      entries => handle()->entries,
      title   => 'admin',
      page_limit => 20,
      prefix  => prefix() || '../';
};

get '/admin/entry/:type/new' => sub {
    my %vars  = @_;
    my $type  = lc $vars{'type'};
    my $class = entry_type_info->{ lc $type }{class};
    if ($class) {
        my $entry = $class->new( id => 'new' );

        return render 'admin/entry',
          entry => $entry,
          form  => Beagle::Web::Form->new(
            field_list => scalar Beagle::Web->field_list($entry) ),
          title  => 'create ' . A($type),
          prefix => prefix() || '../../../';
    }
};

get '/admin/entry/{id:\w{32}}' => sub {
    my %vars = @_;
    my ($id) = $vars{id};

    return redirect '/admin/entries'
      unless handle()->map->{$id};
    render 'admin/entry',
      message => $vars{'message'},
      entry   => handle()->map->{$id},
      form    => Beagle::Web::Form->new(
        field_list => scalar Beagle::Web->field_list( handle()->map->{$id} ) ),
      title  => "update $id",
      prefix => prefix() || '../../';
};

post '/admin/entry/:type/new' => sub {
    my %vars = @_;
    my $type = $vars{'type'};
    my $class = entry_type_info->{ lc $type }{class};
    if ($class) {
        my $entry = $class->new( timezone => handle()->info->timezone );
        if ( $entry->can('author') && !$entry->author ) {
            $entry->author( current_user() );
        }

        if ( $type eq 'comment' && !request()->param('format') ) {

            # make comment's format be plain by default if from web ui
            $entry->format('plain');
        }

        if ( process_fields( $entry, request()->parameters->mixed ) ) {
            my ($created) =
              handle()->create_entry( $entry, message => request()->param('message') );

            if ($created) {
                add_attachments( $entry, request()->upload('attachments') );
                if ( request()->header('Accept') =~ /json/ ) {
                    my $ret = {
                        status    => 'created',
                        parent_id => $entry->parent_id,
                        content   => render( 'entry_comment', entry => $entry ),
                    };
                    status(201);
                    content_type('application/json');
                    return to_json($ret);
                }

                if ( $type eq 'comment' ) {
                    return
                        redirect '/entry/'
                      . $entry->parent_id
                      . '?message=created' . '#'
                      . $entry->id;
                }
                else {
                    return
                        redirect '/entry/'
                      . $entry->id
                      . '?message=created';
                }
            }
            else {
                if ( request()->header('Accept') =~ /json/ ) {
                    my $ret = {
                        status  => 'error',
                        message => 'failed to create',
                    };
                    content_type('application/json');
                    return to_json($ret);
                }
            }
        }
        else {
            return render "admin/entry/$type/new",
              entry => $entry,
              form  => Beagle::Web::Form->new(
                field_list => scalar Beagle::Web->field_list($entry) ),
              message => 'invalid';
        }
    }

    if ( request()->header('Accept') =~ /json/ ) {
        my $ret = {
            status  => 'error',
            content => "invalid type: $type",
        };
        content_type('application/json');
        return to_json($ret);
    }
    else {
        redirect '/admin/entries';
    }
};

post '/admin/entry/{id:\w{32}}' => sub {
    my %vars = @_;
    my ($id) = $vars{id};

    if ( my $entry = handle()->map->{$id} ) {

        if ( process_fields( $entry, request()->parameters->mixed ) ) {

            handle()->update_entry( $entry, message => request()->param('message') );

            my $del = $vars{'delete-attachments'};
            delete_attachments( $entry, ref $del ? @$del : $del );

            add_attachments( $entry, request()->upload('attachments') );

            render 'admin/entry',
              entry => $entry,
              form  => Beagle::Web::Form->new(
                field_list => scalar Beagle::Web->field_list($entry) ),
              message => 'updated',
              prefix  => prefix() || '../../';
        }
        else {
            render 'admin/entry',
              entry => $entry,
              form  => Beagle::Web::Form->new(
                field_list => scalar Beagle::Web->field_list($entry) ),
              message => 'invalid',
              prefix  => prefix() || '../../';
        }
    }
    else {
        redirect '/admin/entries';
    }
};

post '/admin/entry/delete' => sub {
    my $id = request()->param('id');

    if ( request()->header('Accept') =~ /json/ ) {
        content_type('application/json');
    }

    if ( my $entry = handle()->map->{$id} ) {
        handle()->delete_entry($entry);
        my $ret = { status => 'deleted' };
        $ret->{redraw_menu} = 1 unless $entry->type eq 'comment';
        return to_json($ret);
    }
    else {
        return to_json {
            status  => 'error',
            message => 'not exist'
        };
    }

    redirect '/admin/entries';
};

any '/admin/info' => sub {
    my $entry = handle()->info;
    redirect '/admin/entry/' . $entry->id;
};

get '/favicon.ico' => sub {
    if (   handle()->info->avatar
        && handle()->info->avatar ne '/favicon.ico' )
    {
        redirect handle()->info->avatar;
    }
    else {
        redirect '/system/images/beagle.png';
    }
};

get '/static/*' => sub {
    my %vars = @_;
    my @parts = split '/', decode_utf8 $vars{splat}[0];
    my $file =
      encode( 'locale_fs',
        catfile( static_root( handle() ), @parts ) );
    return unless -e $file && -r $file;

    content_type( mime_type($file) );
    return scalar read_file $file;
};

post '/utility/markitup' => sub {
    my $data = request()->param('data');
    return unless $data;
    my $format = request()->param('format');
    return unless $format;

    my $content;
    my $parse_method = Beagle::Util->can( "parse_$format" );
    if ( $parse_method ) {
        $content = $parse_method->($data);
    }

    render 'markitup',
      content => $content,
      prefix  => prefix() || '../';
};

any '/utility/markitup_preview' => sub {
    render 'markitup_preview', prefix  => prefix() || '../';
};

get '/extra/*' => sub {
    my %vars = @_;
    my $name = decode_utf8 $vars{splat}[0];
    return unless $name;
    return unless Beagle::Web->template_exists("extra/$name");
    render("extra/$name");
};

get '/admin/term' => sub {
    render('admin/term');
};

post '/admin/term' => sub {
    my $data;
    content_type('application/json');

    eval { $data = from_json( request()->content, { utf8 => 1 } ) };
    if ( $@ ) {
        return to_json( { error => { message => decode( locale => $@ ) } } );
    }
    else {

        my $params = $data->{params} || [];

        local $ENV{BEAGLE_WEB_TERM} = 1;
        local @ARGV = ( $data->{method}, @$params );
        my $out;
        open my $out_fh, '>', \$out or die $!;
        local *STDOUT = $out_fh;
        local *STDERR = $out_fh;

        eval { Beagle::Cmd->run };
        my $ret = { id => $data->{id} };
        if ($@) {
            $ret->{error}{message} = decode( locale => $@ );
        }
        else {
            $ret->{result} = decode( locale => $out );
        }
        return to_json($ret);
    }
};

1;

__END__

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


