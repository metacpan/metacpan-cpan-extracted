package PlainSpeaking::Routes::BlogContent;

use Moo;
with 'Articulate::Role::Routes';
use Articulate::Syntax::Routes;

my $zone_id = 'blog';

get '/' => sub {
  my $self    = shift;
  my $request = shift;
  $self->service->process_request(
    list => {
      location => "zone/$zone_id/article",
      sort     => {
        field => "schema/core/dateCreated",
        order => 'desc',
      },
    }
  );
};

get '/article/:article_id' => sub {
  my $self       = shift;
  my $request    = shift;
  my $article_id = $request->params->{'article_id'};
  $self->service->process_request(
    read => {
      location => "zone/$zone_id/article/$article_id",
    }
  );
};

post '/article/:article_id' => sub {
  my $self       = shift;
  my $request    = shift;
  my $article_id = $request->params->{'article_id'};
  my $title      = $request->params->{'title'};
  my $content    = $request->params->{'content'};
  $self->service->process_request(
    update => {
      location => "zone/$zone_id/article/$article_id",
      content  => $content,
      meta     => {
        schema =>
          { core => { content_type => 'text/markdown', title => $title } }
      },
    }
  );
};

get '/login' => sub {
  my $self    = shift;
  my $request = shift;
  $self->service->process_request( login_form => {} );
};

get '/create' => sub {
  my $self    = shift;
  my $request = shift;
  $self->service->process_request(
    create_form => {
      location => "zone/$zone_id",
    }
  );
};

post '/create' => sub {
  my $self       = shift;
  my $request    = shift;
  my $article_id = $request->params->{'article_id'};
  my $title      = $request->params->{'title'};
  my $content    = $request->params->{'content'};
  return $self->service->process_request(
    error => {
      simple_message => 'Parameter article_id is required'
    }
  ) unless defined $article_id and $article_id ne '';
  my $location = "zone/$zone_id/article/$article_id";
  my $response = $self->service->process_request(
    create => {
      location => $location,
      content  => $content,
      meta     => {
        schema =>
          { core => { content_type => 'text/markdown', title => $title } }
      },
    }
  );

  # if ($response) {
  #   $self->process_request(
  #     group_add => {
  #       location => $location,
  #       group    => "zone/$zone_id/group/all",
  #     }
  #   );
  # }
  return $response;
};

post '/preview' => sub {
  my $self       = shift;
  my $request    = shift;
  my $title      = $request->params->{'title'};
  my $article_id = $request->params->{'article_id'};
  return $self->service->process_request(
    error => {
      simple_message => 'Parameter article_id is required'
    }
  ) unless defined $article_id and $article_id ne '';
  my $content = $request->params->{'content'};
  $self->service->process_request(
    preview => {
      location => "zone/$zone_id/article/$article_id",
      content  => $content,
      meta     => {
        schema =>
          { core => { content_type => 'text/markdown', title => $title } }
      },
    }
  );
};

get '/article/:article_id/edit' => sub {
  my $self       = shift;
  my $request    = shift;
  my $article_id = $request->params->{'article_id'};
  $self->service->process_request(
    edit_form => {
      location => "zone/$zone_id/article/$article_id",
    }
  );
};

get '/upload' => sub {
  my $self    = shift;
  my $request = shift;
  $self->service->process_request(
    upload_form => {
      location => "assets/images",
    }
  );
};

post '/upload' => sub {
  my $self     = shift;
  my $request  = shift;
  my $image_id = $request->params->{'image_id'};
  my $title    = $request->params->{'title'};
  my $content  = $self->framework->upload('image');
  return $self->service->process_request(
    error => {
      simple_message => 'Parameter image_id is required'
    }
  ) unless defined $image_id and $image_id ne '';
  my $location = "assets/images/image/$image_id";
  my $response = $self->service->process_request(
    create => {
      location => $location,
      content  => $content,
      meta     => {
        schema => {
          core => {
            file         => 1,
            content_type => $content->content_type
          }
        }
      }
    }
  );
  return $response
    ? $self->service->process_request(
    read => {
      location => $location,
    }
    )
    : $response;
};

get '/image/:image_id' => sub {
  my $self     = shift;
  my $request  = shift;
  my $image_id = $request->params->{'image_id'};
  $self->service->process_request(
    read => {
      location => "assets/images/image/$image_id",
    }
  );
};

1;
