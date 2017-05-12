package CGI::Application::MailPage;
use base 'CGI::Application';
use strict;
use CGI::Application;
use File::Spec;
use HTML::Template;
use HTML::TreeBuilder;
use HTTP::Date;
use MIME::Entity;
use Mail::Header;
use Mail::Internet;
use Email::Valid;
use Net::SMTP;
use Text::Format;
use URI;
use Data::FormValidator;
use Fcntl qw(:flock);

$CGI::Application::MailPage::VERSION = '1.7';

sub setup {
    my $self = shift;
    $self->start_mode('show_form');
    $self->mode_param('rm');
    $self->run_modes(
                   show_form => \&show_form,
                   send_mail => \&send_mail,
    );

    # make sure we have required params
    die "You must set either 'document_root' or 'remote_fetch' in PARAMS!"
        unless defined $self->param('document_root') || $self->param('remote_fetch');

    die "You must set 'your.smtp.server' in PARAMS!"
        unless defined $self->param('smtp_server');

    # default custom validation_profile is an empty hash
    $self->param(validation_profile => {} )
        unless defined($self->param('validation_profile'));
}

sub show_form {
    my ($self, $err_msgs) = @_;
    my $query = $self->query;

    my $page = $query->param('page');
    if (not defined $page) {
        unless($self->param('use_page_param')) {
            $page = $query->referer();
            return $self->error(
                "Sorry, I can't tell what page you want to send. " .
                "You need to be using either Netscape 4 or Internet Explorer 4 (or newer) " .
                "to use this feature. Please upgrade your browser and try again!"
            )
                unless defined $page;
        } else {
            return $self->error("no value for page param!") 
                unless defined $page;
        }
    }    

    my $template;
    if ($self->param('form_template')) {    
        $template = $self->load_tmpl($self->param('form_template'),
                                    die_on_bad_params   => 0,
                                    cache               => 1, 
                                    associate           => $query
        );
    
    } else {
        my @path = $self->tmpl_path;
        @path = @{ $self->tmpl_path} if(ref($path[0]) eq 'ARRAY');
        $template = $self->load_tmpl('CGI/Application/MailPage/templates/form.tmpl',
                                    die_on_bad_params   => 0,
                                    path                => [@path, @INC],
                                    cache               => 1,
                                    associate           => $query,
        );
    }

    my %formats = (
        both_attachment => 'Both Text and Full HTML as Attachments',
        html            => 'Full HTML',
        html_attachment => 'Full HTML as an Attachment',
        text            => 'Plain Text',
        text_attachment => 'Plain Text as an Attachment',
        url             => 'Just A Link',
    );
    #create the default dropdown menu
    $template->param(FORMAT_SELECTOR => 
                   $query->popup_menu(-name => 'format',
                                      '-values' => [ sort(keys %formats) ],
                                      -labels => \%formats,
                                      -default => 'both_attachment',
                   )
    );
    #create a loop that the user can use as they wish
    my @format_loop = ();
    foreach my $key (sort(keys(%formats))) {
        push(@format_loop, { value => $key, label => $formats{$key}});
    }
    $template->param(FORMAT_OPTIONS => \@format_loop);
  
    # set the default 'subject' as the email subject
    $query->param('subject' => $self->param('email_subject'))
        unless($query->param('subject'));
    # if we have any alerts or error messages
    if( $err_msgs && ref $err_msgs eq 'HASH' ) {
        $template->param(%$err_msgs);
    } 
    $template->param(%{$self->param('extra_tmpl_params')})
        if($self->param('extra_tmpl_params'));
    return $template->output();
}

sub send_mail {
    my $self = shift;
    my $query = $self->query;

    # the default validation profile
    my %validation_profile = (
        required    => [qw(
            name from_email to_emails format page subject
        )],
        optional    => [qw(note)],
        constraints => {
            name          => qr/^[\w '-\(\),\.]{1,50}$/,
            from_email    => 'email',
            to_emails     => sub {
                my @emails = split(/\s*,\s*|\s+/, shift);
                # make sure there aren't too many 
                # if we have 'max_emails_per_request'
                if( 
                    $self->param('max_emails_per_request')
                    && scalar @emails > $self->param('max_emails_per_request')
                ) {
                    return;
                }
                # check for valid email addresses
                foreach my $email (@emails) {
                    if(! Email::Valid->address($email) ) {
                        return;
                    }
                }
                return \@emails;
            },
            subject       => qr/^[\w '-\(\),\.\?\!]{1,50}$/,
            note          => qr/^[^\0]{1,250}$/,
            format        => sub {
                my $val = shift;
                my @valid_formats = qw(
                    both_attachment html html_attachment 
                    text text_attachment url
                );
                if( grep { $val eq $_ } @valid_formats ) {
                    return $val;
                }
                return;
            },
            page        => qr/^[^\n\0]{1,256}$/, # TODO - what should this be?
        },
        untaint_all_constraints => 1,
    );

    # merge this default with the custom profile
    # first merge the 'constraints'
    if( $self->param('validation_profile')->{constraints} ) {
        $validation_profile{constraints} = {
            %{$validation_profile{constraints}},
            %{ $self->param('validation_profile')->{constraints} }
        };
    }
    delete $self->param('validation_profile')->{constraints};
    # now merge the rest
    %validation_profile = ( 
        %validation_profile, 
        %{ $self->param('validation_profile') },
    );

    # now validate the data
    my $results = Data::FormValidator->check($query, \%validation_profile);

    # create any error messages if necessary.
    if( $results->has_invalid || $results->has_missing ) {
        my %err_msgs = ();
        # look at each invalid
        foreach my $invalid ($results->invalid) {
            $err_msgs{"error_$invalid"} = 1;
            $err_msgs{"invalid_$invalid"} = 1;
            $err_msgs{"any_errors"} = 1;
            $err_msgs{"any_invalid"} = 1;
        }
        # look at each missing
        foreach my $missing ($results->missing) {
            $err_msgs{"error_$missing"} = 1;
            $err_msgs{"missing_$missing"} = 1;
            $err_msgs{"any_errors"} = 1;
            $err_msgs{"any_missing"} = 1;
        }

        # for backwards compatability, add an 'alert' parameter
        # for older templates that hold's the first error message we encounter
        if( $err_msgs{error_name} ) {
            $err_msgs{alert} = "Please fill in your name in the form below.";
        } elsif( $err_msgs{invalid_from_email} ) {
            $err_msgs{alert} = "Your email address is invalid - it should look like name\@host.com.";
        } elsif( $err_msgs{missing_from_email} ) {
            $err_msgs{alert} = "Please fill in your email address in the form below.";
        } elsif( $err_msgs{invalid_to_emails} ) {
            $err_msgs{alert} = "One of your friend's email addresses is invalid - it should look like name\@host.com.";
        } elsif( $err_msgs{missing_to_emails} ) {
            $err_msgs{alert} = "Please fill in your friends' email addresses in the form below.";
        } elsif( $err_msgs{error_subject} ) {
            $err_msgs{alert} = "Please enter a Subject for the email in the form below.";
        }

        # show these errors
        return $self->show_form(\%err_msgs);
    }

    # get the valid data
    my $valid_data = $results->valid();
    my ($to_emails, $from_email, $name, $subject, $page, $note, $format) =
        map { $valid_data->{$_} } qw(to_emails from_email name subject page note format);
    
    #make sure this page is either relative or within the acceptable_domains
    if(
        $self->param('acceptable_domains')  #if we have any domains 
        && (ref($self->param('acceptable_domains')) eq 'ARRAY')   #if it's an array ref
        && $page =~ m#^https?://([^/:]+)#               #if the path's not relative
    ) 
    {
        my $domain = $1;
        return $self->error("The domain for that desired page is not acceptable!")
            unless( grep { lc($domain) eq lc($_) } @{$self->param('acceptable_domains')});
    }
  
    # make sure we haven't exceeded our hourly limit
    if( $self->param('max_emails_per_hour') ) {
        my $file = $self->param('max_emails_per_hour_file');
        unless( $file ) {
            die "max_emails_per_hour_file ($file) must exist and be writable"
                . " in order to use max_emails_per_hour!";
        }
        my ($error, $count, $last_time);
        my $current_time = time();
        # if already exists then open it and read the data
        if( -e $file ) {
            open(my $IN, $file) or die "Could not open $file for reading! $!";
            ($last_time, $count) = split(qr/:/, <$IN>);
            close($IN) or die "Could not close $file! $!";
            $last_time ||= 0;
            $count ||= 0;
            # find out if we've done this within the hour
            # if the difference is less than 1 hour, increase the count
            # and make sure it's less than the hourly total
            if( $current_time - $last_time < ( 60 * 60 ) ) {
                $count += scalar(@$to_emails);
                if( $count > $self->param('max_emails_per_hour') ) {
                    $error = "Hourly limit on emails exceeded!";
                }
                # keep the last recorded time.
                $current_time = $last_time;
            } else {
                $count = scalar(@$to_emails);
            }
        # else the file doesn't exist
        } else {
            $count = scalar(@$to_emails);
        }

        # now save the time and count
        open(my $OUT, ">", $file) or die "Could not open $file for writing! $!";
        flock($OUT, LOCK_EX) or die "Could not obtain lock on $file! $!";
        print $OUT "$current_time:$count";
        close($OUT) or die "Could not close $file! $!";

        # if we have an error then return it
        return $self->error($error) if( $error );
    }

    # find the HTML file to open (if it's not a remote fetch)
    my ($filename, $base_url, $base);
    unless( $self->param('remote_fetch') && ($page =~ m!^https?://!) ) {
        $filename = $self->_find_html_file($page);
        return $self->error("Unable to find file $filename for page $page (might be empty or unreadable): $!")
            unless -e $filename and -r _ and -s _;
        my ($vol, $dir, $file) = File::Spec->splitpath($filename);

        $base_url = $page;
        $base_url =~ s/\Q$file\E//;
 
        # if file is empty, assume index.html
        if (not defined $file or not length $file) {
            $file = 'index.html';
            $filename .= '/index.html';
        }
 
        my $ext;
        ($base, $ext) = $file =~ /(.*)\.([^\.]+)$/;
    } else {
        $base_url = URI->new($page);
        $base_url = $base_url->scheme . '://' . $base_url->authority . '/' . $base_url->path; 
    }

    # open the email template
    my $template;
    if ($self->param('email_template')) {    
        $template = $self->load_tmpl($self->param('email_template'),
                                    die_on_bad_params   => 0,
                                    cache               => 1,
        );
    } else {
        my @path = $self->tmpl_path;
        @path = @{ $self->tmpl_path} if(ref($path[0]) eq 'ARRAY');
        $template = $self->load_tmpl('CGI/Application/MailPage/templates/email.tmpl',
                                    die_on_bad_params   => 0,
                                    path                => [@path, @INC],
                                    cache               => 1,
        );
    }
    $template->param(%$valid_data);
    $template->param(%{$self->param('extra_tmpl_params')})
        if($self->param('extra_tmpl_params'));

    # get the IP address of the original sender
    my $sender_ip = $ENV{HTTP_X_FORWARDED_FOR} || $ENV{REMOTE_ADDR} || '';
    # $msg will end up with either a Mail::Internet or MIME::Entity object.
    my $msg;

    # are we doing attachments?
    if (index($format, '_attachment') != -1) {
        # open up a MIME::Entity for our msg
        $msg = MIME::Entity->build(
            'Type'             => "multipart/mixed",
            'From'             => "$name <$from_email>",
            'Reply-To'         => "$name <$from_email>",
            'To'               => $to_emails,
            'Subject'          => $subject,
            'Date'             => HTTP::Date::time2str(time()),
            'X-Originating-Ip' => $sender_ip,
        );

        $msg->attach(Data => $template->output);

        # attach the straight HTML if requested
        if ($format =~ /^(both|html)/) {
            my $buffer = "";
            if ($self->param('read_file_callback')) {
                my $callback = $self->param('read_file_callback');
                $buffer = $callback->($filename);
            } elsif( $self->param('remote_fetch') && ($page =~ /^https?:\/\//) ) {
                #fetch this page with LWP
                require LWP::UserAgent;
                require HTTP::Request;
                my $agent = LWP::UserAgent->new();
                my $response = $agent->request(HTTP::Request->new(GET => $page));
                if( $response->is_success ) {
                    $buffer = $response->content();
                } else {
                    return $self->error("Unable to retrieve remote page $page");
                }
            } else {
                open(HTML, $filename) or return $self->error("Can't open $filename : $!");
                while(read(HTML, $buffer, 10240, length($buffer))) {}      
                close(HTML);
            }
       
            # add <BASE> tag in <HEAD>
            $buffer =~ s/(<\s*[Hh][Ee][Aa][Dd].*?>)/$1\n<base href=$base_url>\n/
                if( $base_url );
      
            my $attached_filename = $base ? "$base.html" : $page;
            $msg->attach(
                    Data        => $buffer,
                    Type        => 'text/html',
                    Filename    => $attached_filename,
            );
        }

        # attach text translation
        if ($format =~ /^(both|text)/) {
            my $new_filename = $base ? "$base.txt" : "$page.txt";
            $msg->attach(
                    Data        => $self->_html2text($filename, $page),
                    Type        => 'text/plain',
                    Filename    => $new_filename,
            );
        }

    } else {
        # non attachment mail
        my $header = Mail::Header->new();
        $header->add(From => "$name <$from_email>");
        $header->add('Reply-To' => "$name <$from_email>");
        $header->add(To => join(', ', @$to_emails));
        $header->add(Subject  => $subject);
        $header->add(Date => HTTP::Date::time2str(time()));
        $header->add('X-Originating-Ip' => $sender_ip)
            if( $sender_ip );

        my @lines;
        push(@lines, $template->output());

        if ($format =~ /^(both|text)/) {
            push(@lines, "\n---\n\n");
            push(@lines, $self->_html2text($filename, $page));
        }
    
        if ($format =~ /^(both|html)/) {
            push(@lines, "\n---\n\n");
            if ($self->param('read_file_callback')) {
                my $callback = $self->param('read_file_callback');
                my $buffer = $callback->($filename);
                push(@lines, split("\n", $buffer));
            } elsif( $self->param('remote_fetch') && ($page =~ /^https?:\/\//) ) {
                #fetch this page with LWP
                require LWP::UserAgent;
                require HTTP::Request;
                my $agent = LWP::UserAgent->new();
                my $response = $agent->request(HTTP::Request->new(GET => $page));
                if( $response->is_success ) {
                    my $buffer = $response->content();
                    @lines = split(/\r?\n/, $buffer);
                } else {
                    return $self->error("Unable to retrieve remote page $page");
                }
            } else {
                open(HTML, $filename) or return $self->error("Can't open $filename : $!");
                push(@lines, <HTML>);
                close(HTML);
            }
        }

        if ($format =~ /url/) {
            push(@lines, "\n$page");
        }

        $msg = Mail::Internet->new([], Header => $header, Body => \@lines);
        return $self->error("Unable to create Mail::Internet object!")
            unless defined $msg;
    }
    
    # send the message using SMTP - other methods can be added later
    unless($self->param('dump_mail')) {
        my $smtp = Net::SMTP->new($self->param('smtp_server'));
        return $self->error("Unable to connect to SMTP server ".$self->param('smtp_server')." : $!")
            unless defined $smtp and UNIVERSAL::isa($smtp,'Net::SMTP');
        $smtp->debug(1) if $self->param('smtp_debug');
  
        $smtp->mail("$name <$from_email>");
        foreach (@$to_emails) {
            $smtp->to($_);
        }
        $smtp->data();
        $smtp->datasend($msg->as_string());
        $smtp->dataend();
        $smtp->quit();

    } else {
        # debuging hook for test.pl
        my $mailref = $self->param('dump_mail');
        $$mailref = $msg->as_string();
        return $self->error("Mail Dumped");
    }   

    # all done
    return $self->show_thanks;
}

sub show_thanks {
    my $self = shift;
    my $query = $self->query;
    my $page = $query->param('page');

    my $template;
    if ($self->param('thanks_template')) {    
        $template = $self->load_tmpl($self->param('thanks_template'),
                                    die_on_bad_params   => 0,
                                    cache               => 1,
        );
    } else {
        my @path = $self->tmpl_path;
        @path = @{ $self->tmpl_path} if(ref($path[0]) eq 'ARRAY');
        $template = $self->load_tmpl('CGI/Application/MailPage/templates/thanks.tmpl',
                                    die_on_bad_params   => 0,
                                    path                => [@path, @INC],
                                    cache               => 1,
        );
    }

    $template->param(PAGE => $page);
    $template->param(%{$self->param('extra_tmpl_params')})
        if($self->param('extra_tmpl_params'));
    return $template->output();
}


sub error {
    my ($self, $msg) = @_;
    my $template;

    if($self->param('error_template')) {
        $template = $self->load_tmpl( $self->param('error_template'),
                                    die_on_bad_params   => 0,
                                    cache               => 1,
        );
    } else {
        my @path = $self->tmpl_path;
        @path = @{ $self->tmpl_path} if(ref($path[0]) eq 'ARRAY');
        $template = $self->load_tmpl( 'CGI/Application/MailPage/templates/error.tmpl',
                                    die_on_bad_params   => 0,
                                    path                => [@path, @INC],
                                    cache               => 1,
        );
    }

    $template->param(error => $msg);
    $template->param(%{$self->param('extra_tmpl_params')})
        if($self->param('extra_tmpl_params'));
    return $template->output();
}

sub _find_html_file {
    my $self = shift;
    my $url = shift;
    my $path;

    # if it doesn't start with http, its relative to web root
    if($url =~ m!^https?://([-\w\.:]+)/(.*)!) {
        my $host = $1;
        $path = $2;
        # if the path starts with a ~user thing, remove it
        $path =~ s!~[^/]+/!!;
    } else {
        $path = ($url =~ /^\//) ? $url : "/$url";   #make sure it has a preceding path
    }

    # now make sure we don't allow any '../' sections to try and hack the server
    $path =~ s/\.\.\///g;
    # append it to document_root and return it
    return File::Spec->join($self->param('document_root'), $path);
}  
    
# takes an html file and returns text.  This code was taken and
# modified from html2text.pl by Ave Wrigley.  I don't really
# understand most of it, but it seems to work well.

#--------------------------------------------------------------------------
#
# prefixes to convert tags into - some are converted back to Text::Format
# formatting later
#
#--------------------------------------------------------------------------

my %prefix = (
              'li'        => '* ',
              'dt'        => '+ ',
              'dd'        => '- ',
             );

my %underline = (
                 'h1'        => '=',
                 'h2'        => '-',
                 'h3'        => '-',
                 'h4'        => '-',
                 'h5'        => '-',
                 'h6'        => '-',
                );

my @heading_number = ( 0, 0, 0, 0, 0, 0 );

sub _html2text {
  my $self = shift;
  my $filename = shift;
  my $page = shift;

  my $html_tree = new HTML::TreeBuilder;
  my $text_formatter = new Text::Format;
  $text_formatter->firstIndent( 0 );

  my $result = "";

  #----------------------------------------------------------------------
  #
  # get_text - get all the text under a node
  #
  #----------------------------------------------------------------------

  sub get_text
    {
      my $this = shift;
      my $text = '';
      
      # iterate though my children ...
      return unless defined $this->content;
      for my $child ( @{ $this->content } )
        {
          # if the child is also non-text ...
          if ( ref( $child ) )
            {
              # traverse it ...
              $child->traverse(
                               # traveral callback
                               sub {
                                 my( $node, $startflag, $depth ) = @_;
                                 # only visit once
                                 return 0 unless $startflag;
                                 # if it is non-text ...
                                 if ( ref( $node ) )
                                   {
                                     # recurse get_text
                                     $text .= get_text( $node );
                                   }
                                 # if it is text
                                 else
                                   {
                                     # add it to $text
                                     $text .= $node if $node =~ /\S/;
                                   }
                                 return 0;
                               },
                               0
                              );
            }
          # if it is text
          else
            {
              # add it to $text
              $text .= $child if $child =~ /\S/;
            }
        }
      return $text;
    }
  
  #--------------------------------------------------------------------------
  #
  # get_paragraphs - routine for generating an array of paras from a given node
  #
  #--------------------------------------------------------------------------
  
  sub get_paragraphs
    {
      my $this = shift;
      
      # array to save paragraphs in
      my @paras = ();
      # avoid -w warning for .= operation on undefined
      $paras[ 0 ] = '';
      
      # iterate though my children ...
      for my $child ( @{ $this->content } )
        {
          # if the child is also non-text ...
          if ( ref( $child ) )
            {
              # traverse it ...
              $child->traverse(
                               # traveral callback
                               sub {
                                 my( $node, $startflag, $depth ) = @_;
                                 # only visit once
                                 return 0 unless $startflag;
                                 # if it is non-text ...
                                 if ( ref( $node ) )
                                   {
                                     # if it is a list element ...
                                     if ( $node->tag =~ /^(?:li|dd|dt)$/ )
                                       {
                                         # recurse get_paragraphs
                                         my @new_paras = get_paragraphs( $node );
                                         # pre-pend appropriate prefix for list
                                         $new_paras[ 0 ] =
                                           $prefix{ $node->tag } . $new_paras[ 0 ]
                                             ;
                                         # and update the @paras array
                                         @paras = ( @paras, @new_paras );
                            # and traverse no more
                                         return 0;
                                       }
                                     else
                                       {
                                         # any other element, just traverse
                                         return 1;
                                       }
                                   }
                                 else
                                   {
                                     # add text to the current paragraph ...
                                     $paras[ $#paras ] = 
                                       join( ' ', $paras[ $#paras ], $node )
                                         if $node =~ /\S/
                                           ;
                                     # and recurse no more
                                     return 0;
                                   }
                               },
                               0
                              );
            }
          else
            {
              # add test to current paragraph ...
              $paras[ $#paras ] = join( ' ', $paras[ $#paras ], $child )
                if $child =~ /\S/
                  ;
            }
        }
      return @paras;
    }
  
  #--------------------------------------------------------------------------
  #
  # Main
  #
  #--------------------------------------------------------------------------
  
  # parse the HTML file
  if ($self->param('read_file_callback')) {
    my $callback = $self->param('read_file_callback');
    $html_tree->parse( $callback->($filename) );
  } elsif( $self->param('remote_fetch') && ($page =~ /^https?:\/\//) ) {
      #fetch this page with LWP
      require LWP::UserAgent;
      require HTTP::Request;
      my $agent = LWP::UserAgent->new();
      my $response = $agent->request(HTTP::Request->new(GET => $page));
      if( $response->is_success ) {
          my $buffer = $response->content();
          $html_tree->parse($buffer);
      } else {
          return $self->error("Unable to retrieve remote page $page");
      }
  } else {
    open(HTML, $filename) or return $self->error("Can't open $filename : $!");
    $html_tree->parse( join( '', <HTML> ) );
    close(HTML);
  }

  # main tree traversal routine
  
  $html_tree->traverse(
                       sub {
                         my( $node, $startflag, $depth ) = @_;
                         # ignore what's in the <HEAD>
                         return 0 if ref( $node ) and $node->tag eq 'head';
                         # only visit nodes once
                         return 0 unless $startflag;
                         # if this node is non-text ...
                         if ( ref $node )
                           {
                             # if this is a para  ...
                             if ( $node->tag eq 'p' )
                               {
                                 # iterate sub-paragraphs (including lists) ...
                                 for ( get_paragraphs( $node ) )
                                   {
                                     # if it is a <LI> ...
                                     if ( /^\* / )
                                       {
                                         # indent first line by 4, rest by 6
                                         $text_formatter->firstIndent( 4 );
                                         $text_formatter->bodyIndent( 6 );
                                       }
                                     # if it is a <DT> ...
                                     elsif ( s/^\+ // )
                                       {
                                         # set left margin to 4
                                         $text_formatter->leftMargin( 4 );
                                       }
                                     # if it is a <DD> ...
                                     elsif ( s/^- // )
                                       {
                                         # set left margin to 8
                                         $text_formatter->leftMargin( 8 );
                                       }
                                     # print formatted paragraphs ...
                                     $result .= $text_formatter->paragraphs( $_ );
                                     # and reset formatter defaults
                                     $text_formatter->leftMargin( 0 );
                                     $text_formatter->firstIndent( 0 );
                                     $text_formatter->bodyIndent( 0 );
                                   }
                                 $result .= "\n";
                                 return 0;
                               }
                             # if this is a heading ...
                             elsif ( $node->tag =~ /^h(\d)/ )
                               {
                                 # get the heading level ...
                                 my $level = $1;
                                 # increment the number for this level ...
                                 $heading_number[ $level ]++;
                                 # reset lower level heading numbers ...
                                 for ( $level+1 .. $#heading_number )
                                   {
                                     $heading_number[ $_ ] = 0;
                                   }
                                 # create heading number string
                                 my $heading_number = join( 
                                                           '.', 
                                                           @heading_number[ 1 .. $level ]
                                                          );
                                 # generate heading from number string and heading text ...
                                 # my $text = "$heading_number " . get_text( $node );
                                 my $text = get_text( $node );
                                 # underline it with the appropriate underline character ...
                                 $text =~ s{
                        (.*)
                    }
                                   {
                                     "$1\n" . $underline{ $node->tag } x length( $1 )
                                   }gex
                                     ;
                                 $result .= $text;
                                 return 0;
                               } else {
                                 return 1;
                               }
                           }
                         # if it is text ...
                         else
                           {
                             return 0 unless $node =~ /\S/;
                             $result .= $text_formatter->format( $node );
                             return 0;
                           }
                       },
                       0
                      );

  # filter out comments
  $result =~ s/<!--.*?-->//gs;

  return $result;
}  
  

1;
__END__

=head1 NAME

CGI::Application::MailPage - module to allow users to send HTML pages to friends.

=head1 SYNOPSIS

   use CGI::Application::MailPage;
   my $mailpage = CGI::Application::MailPage->new(
                  PARAMS => { document_root => '/home/httpd', 
                              smtp_server => 'smtp.foo.org' });
   $mailpage->run();

=head1 DESCRIPTION

CGI::Application::MailPage is a CGI::Application module that allows
users to send HTML pages to their friends.  This module provides the
functionality behind a typical "Mail This Page To A Friend" link.

To use this module you need to create a simple "stub" script.  It
should look like:

   #!/usr/bin/perl
   use CGI::Application::MailPage;
   my $mailpage = CGI::Application::MailPage->new(
                  PARAMS => { 
                              document_root => '/home/httpd', 
                              smtp_server => 'smtp.foo.org',
                            },
                );
   $mailpage->run();

You'll need to replace the "/home/httpd" with the real path to your
document root - the place where the HTML files are kept for your site.
You'll also need to change "smtp.foo.org" to your SMTP server.

Put this somewhere where CGIs can run and name it something like
C<mailpage.cgi>.  Now, add a link in the pages you want people to be
able to send to their friends that looks like:

   <A HREF="mailpage.cgi">mail this page to a friend</A>

This gets you the default behavior and look.  To get something more to
your specifications you can use the options described below.

=head1 OPTIONS

CGI::Application modules accept options using the PARAMS arguement to
C<new()>.  To give options for this module you change the C<new()>
call in the "stub" shown above:

   my $mailpage = CGI::Application::MailPage->new(
                      PARAMS => {
                                  document_root => '/home/httpd',
                                  smtp_server => 'smtp.foo.org',
                                  use_page_param => 1,
                                }
                   );

The C<use_page_param> option tells MailPage not to use the REFERER
header to determine the page to mail.  See below for more information
about C<use_page_param> and other options.

=over 4

=item * document_root (required)

This parameter is used to specify the document root for your server -
this is the place where the HTML files are kept.  MailPage needs to
know this so that it can find the HTML files to email.

=item * smtp_server (required)

This must be set to an SMTP server that MailPage can use to send mail.
Future versions of MailPage may support other methods of sending mail,
but for now you'll need a working SMTP server.

=item * use_page_param

By default MailPage uses the REFERER header to determine the page that
the user wants to mail to their friends.  This doesn't always work
right, particularily on very old browsers.  If you don't want to use
REFERER then you can set this option and write your links to the
application as:

   <A HREF="mailpage.cgi?page=http://host/page.html">mail page</A>

You'll have to replace http://host/page.html with the url for each
page you put the link in.  You could cook up some Javascript to do
this for you, but if the browser has working Javascript then it
probably has a working REFERER!

The value of 'page' doesn't have to be a full url, but could be relative
to the web root. For instance this would work as well:

   <A HREF="mailpage.cgi?page=/page.html">mail page</A>


=item * email_subject

The default subject of the email sent from the program.  Defaults to
empty, requiring the user to enter a subject.

=item * form_template

This application uses HTML::Template to generate its HTML pages.  If
you would like to customize the HTML you can copy the default form
template and edit it to suite your needs.  The default form template
is called 'form.tmpl' and you can get it from the distribution or from
wherever this module ended up in your C<@INC>.  Pass in the path to
your custom template as the value of this parameter.

See L<HTML::Template|HTML::Template> for more information about the
template syntax.

=item * thanks_template

The default "Thanks" page template is called 'thanks.tmpl' and you can
get it from the distribution or from wherever this module ended up in
your C<@INC>.  Pass in the path to your custom template as the value
of this parameter.

See L<HTML::Template> for more information about the template syntax.

=item * email_template

The default email template is called 'email.tmpl' and you can get it
from the distribution or from wherever this module ended up in your
C<@INC>.  Pass in the path to your custom template as the value of
this parameter.

See L<HTML::Template> for more information about the template syntax.

=item * error_template

The default template to display errors is called 'error.tmpl' and you
can get it from the distribution or from wherever this module ended up
in your C<@INC>. Pass in the path to you custom template as the value
of this parameter.

=item * read_file_callback

You can provide a subroutine reference that will be called when
MailPage needs to open an HTML file on your site.  This can used to
resolve complex aliasing problems or to perform any desired
manipulation of the HTML text.  The called subroutine recieves one
arguement, the name of the file to be opened.  It should return the
text of the file.  Here's an example that changes all 'p's to 'q's in
the text of the files:

   #!/usr/bin/perl -w
   use CGI::Application::MailPage;

   sub p_to_q {
     my $filename = shift;
     open(FILE, $filename) or die;

     my $buffer;
     while(<FILE>) {
       s/p/q/g;
       $buffer .= $_;
     }
    
     return $buffer;
   }

   my $mailpage = CGI::Application::MailPage->new(
                  PARAMS => { 
                              document_root => '/home/httpd', 
                              smtp_server => 'smtp.foo.org',
                              read_file_callback => \&p_to_q,
                            },
                );
   $mailpage->run();
       

=item * acceptable_domains

You may provide a list (array ref) of domains that are acceptable for this
mailpage instance to send out in the emails. This prevents spammers, etc from
using your mailpage to send out pages of advertisements, etc. If you give any
values to this list, all 'page' urls that are being sent must either be
relative or must be in your list of acceptable domains.

=item * remote_fetch

If this is true, then MailPage will try and perform a remote fetch of the page
using L<LWP> instead of looking on the local filesystem for that page.

=item * extra_tmpl_params

If this value is a hash ref, then it will be combined with the parameters generated
by MailPage for each template. The values in your hash will override those created
by MailPage. The resulting hash will be passed to the template in question. This gives
even more flexibility in making the mailpage section look just like the rest of your
site. It is your responsibility to make sure that these parameters will be in the format
that HTML::Template is expecting.

=item * max_emails_per_request

This is an integer value which limits the number of email addresses that each request
is allowed to send to.
This option is useful to limit your server's potential to aid spammers in their nasty work.

=item * max_emails_per_hour

This is an integer value which limits the number of emails that allowed to be sent in
an hour. MailPage will use a file (specified by L<max_emails_per_hour_file>) to keep 
track of how many have been sent for each hour. If you use this option, make sure that
this location is readable and writeable by the process in question.
This option is useful to limit your server's potential to aid spammers in their nasty work.

=item * max_emails_per_hour_file

This is the name of the file used by L<max_emails_per_hour>. It must be present if you are
using L<max_emails_per_hour>.

=item * validation_profile

This is a validation profile structure for use by L<Data::FormValidator> for validating
user input. This profile is merged with the default profile and will override any existing
rules. This allows you to customize the validation for all, or some of the fields.
See L<INPUT VALIDATION> for more details.

=head1 INPUT VALIDATION

MailPage uses Data::FormValidator to validate the input the user fills in when presented
with the email information form. By default the following validation rules are used:

=over

=item name

Required.
Can only contain word characters (\w), apostrophes ('), hyphens (-), and
open or closed parenthesis, commas (,) and periods (.) with a maximum 
length of 50 characters

=item from_email

Required.
Must be a valid email address.

=item to_emails

Required.
A list of email addresses separated by whitespace or commas. All email addresses
must be valid with at most L<max_emails_per_request> individual addresses.

=item subject

Required.
Can only contain word characters (\w), apostrophes ('), hyphens (-), and
open or closed parenthesis, commas (,), periods (.), question  marks (?)
and exclamation points (!) with a maximum length of 50 characters

Required.

=item note

An optional text to send in the email. Can contain anything but a NULL byte with a
maximum length of 250 characters.

=item format

Required.
Must be one of the following values:

=over

=item both_attachment 

=item html            

=item html_attachment 

=item text            

=item text_attachment 

=item url             

=back

=item page

Can contain any characters except new lines (C<\n>) or NULL bytes with 
a maximum length of 256 characters.

=back

Each field is untainted, so it can be safely processed.
You can customize these rules with the L<validation_profile> parameter.

=head2 Error Messages

MailPage will pass flags for each error message into the template to be used as the
template sees fit. The following error messages are created for each field:

=over

=item missing_$field

If a required field is not present.

=item any_missing

If any required field is not present.

=item invalid_$field

If a field is present but fails validation.

=item any_invalid

If any field fails validation

=item error_$field_name

If a field is not present or fails the validation

=item any_errors

If any field is not present or fails the validation

=back

=head1 AUTHOR

Copyright 2002, Sam Tregar (sam@tregar.com).

Co-maintainer Michael Peters (mpeters@plusthree.com).

Questions, bug reports and suggestions can be sent to the
CGI::Application mailing list.  You can subscribe by sending a blank
message to cgiapp-subscribe@lists.vm.com.  See you there!

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Application|CGI::Application>, L<HTML::Template|HTML::Template>

=cut
