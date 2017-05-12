# please insert nothing before this line: -*- mode: cperl; cperl-indent-level: 4; cperl-continued-statement-offset: 4; indent-tabs-mode: nil -*-

package Apache2::PodBrowser;

use 5.008008;
use strict;

{our $VERSION = '0.08'}

use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::RequestIO ();
use Apache2::Response ();
use Apache2::URI ();
use Apache2::Log ();
use APR::Finfo ();
use APR::Table ();
use Apache2::Const -compile => qw/OK DECLINED REDIRECT NOT_FOUND SERVER_ERROR/;
use APR::Const -compile => qw/FINFO_NORM FILETYPE_DIR FILETYPE_REG
                              FILETYPE_NOFILE SUCCESS ENOENT/;
use Pod::Find;
use Pod::Simple::HTML;

use constant {
  INDEX_NORMAL=>0,
  INDEX_PODINDEX=>1,
  INDEX_PODCACHED=>10,
  INDEX_FUNCINDEX=>2,
};

sub _indexlink {
    ("<div class=\"uplink\">\n".
     join( '', map {
         "    <a href=\"$_->[1]\">$_->[0]</a>\n";
     } ($_[0] ==INDEX_PODINDEX  ? (['Function and Variable Index', './??'])
        : $_[0]==INDEX_PODCACHED ? (['Function and Variable Index', './??'],
                                    ['Update POD Cache', './-'])
        : $_[0]==INDEX_FUNCINDEX ? (['Pod Index', './'])
        : (['Pod Index', './'], ['Function and Variable Index', './??']))).
     "</div>\n");
}

sub _header {
    my ($kind, $style)=@_;

    my ($title, $uplink)=
        ($kind==INDEX_PODINDEX ? ('POD Index', _indexlink($kind))
         :$kind==INDEX_PODCACHED ? ('POD Index', _indexlink($kind))
         :$kind==INDEX_FUNCINDEX ? ('Function and Variable Index',
                                    _indexlink($kind))
         :());

    <<"EOF";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html><head><title>$title</title>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" >
<link rel="stylesheet" type="text/css" title="pod_stylesheet" href="$style">

</head>
<body class='podindex'>
$uplink<h1>$title</h1>
EOF
}

sub _footer {"</body></html>\n"}

{
    my ($current, @index);
    my %html=('"'=>'&quot;', '<'=>'&lt;', '>'=>'&gt;', '&'=>'&amp;');

    sub _reset_link_generator { ($current, @index)=('') }

    sub _link {
        my ($name, $linkprefix)=@_;

        my $prefix='';
        my $firstchar=substr($name, 0, 1);
        unless( $firstchar eq $current ) {
            push @index, $firstchar;
            $prefix="<h2><a name=\"$firstchar\">$firstchar</a></h2>\n";
            $current=$firstchar;
        }

        my $display;
        if( length $name>35 ) {
            $display='...'.substr($name, -32);
        } else {
            $display=$name;
        }
        my $title=$name;
        $name=~s{([^A-Za-z0-9\-_.!~*'()/:\$@&=+,;?\\\]\[^`|<>{}])}
                {sprintf("%%%02X",ord($1))}eg;
        for my $x ($title, $display) {
            $x=~s/(["<>&])/$html{$1}/ge;
        }
        $prefix."<a href=\"./$linkprefix$name\" title=\"$title\">$display</a>";
    }

    sub _gen_index {
        "<div class=\"indexgroup\"><div>\n    ".join("\n    ", map {
            "<a href=\"#$_\">$_</a>";
        } @index)."\n</div></div>\n";
    }
}

sub _stylesheet {
    my ($r)=@_;

    my $stylesheet=$r->dir_config('STYLESHEET') || '';
    if ($stylesheet=~/^auto$/i) {
        $stylesheet='./auto.css';
    } elsif ($stylesheet=~/^fancy$/i) {
        $stylesheet='./fancy.css';
    }

    return $stylesheet;
}

sub _findpod {
    my ($r, $name, $ignore_NOINC)=@_;
    $name=~s!^/!!;
    $name=Pod::Find::pod_where
        ( {
           -inc=>$ignore_NOINC || !$r->dir_config->get('NOINC'),
           -dirs=>[$r->dir_config->get('PODDIR')],
          },
          $name );
    die \Apache2::Const::NOT_FOUND unless( length $name );

    return $name;
}

sub update_finfo {
    my ($r, $name)=@_;

    $r->finfo(APR::Finfo::stat($name, APR::Const::FINFO_NORM,
                               $r->pool)) if defined $name;

    $r->set_last_modified($r->finfo->mtime);
    $r->set_etag;
    my $rc=$r->meets_conditions;
    die \$rc unless $rc==Apache2::Const::OK;
}

sub _findex {
    my ($r)=@_;

    my @links=do {
        local $_;
        my %unique;

        open my $f, '<', _findpod($r, 'perlfunc', 1) or
            die \Apache2::Const::NOT_FOUND;

        while ( <$f> ) {
            /^=head2 Alphabetical Listing of Perl Functions/ and last;
        }

        my $level=0;
        while ( <$f> ) {
            if( ($level==0 && /^=over/)..($level==1 && /^=back/) ) {
                /^=over/ and $level++;
                /^=back/ and $level--;
                $level==1 && /^=item ([-\w]+)/ and undef $unique{$1};
            }
        }

        open my $f, '<', _findpod($r, 'perlvar', 1) or
            die \Apache2::Const::NOT_FOUND;

        my $level=0;
        while ( <$f> ) {
            if( ($level==0 && /^=over 8/)..($level==1 && /^=back/) ) {
                /^=over/ and $level++;
                /^=back/ and $level--;
                $level==1 && /^=item (?!IO::|HANDLE|\$\w+\{expr\})(.+)/
                    and do {
                        my $name=$1;
                        $name='$1..$N' if $name=~/digit/i;
                        undef $unique{$name};
                    };
            }
        }

        _reset_link_generator;
        map {_link($_, '?')} sort keys %unique;
    };

    return (_header(INDEX_FUNCINDEX, _stylesheet($r)).
            _gen_index.
            join("\n", @links)."\n".
            _footer);
}

sub __pod_idx {
    my ($r)=@_;
    local $SIG{__WARN__}=sub{}; # silence some warnings

    my %unique;
    my $x=1;
    undef @unique{grep {
        $x^=1;
    } Pod::Find::pod_find({
                           -inc=>!$r->dir_config->get('NOINC'),
                           -script=>1,
                          },
                          $r->dir_config->get('PODDIR'))};
    return sort keys %unique;
}

{
    my %cachedb;
    sub _update_cache {
        my ($r, $fn, $force)=@_;
        my $db;
        eval {
            require MMapDB;
            if( !$force and exists $cachedb{$fn} ) {
                $db=$cachedb{$fn};
                $db->start;
            } else {
                if( exists $cachedb{$fn} ) {
                    $db=$cachedb{$fn};
                } else {
                    $cachedb{$fn}=$db=MMapDB->new(filename=>$fn);
                }
                if( !$db->start or $force ) {
                    $db->begin;
                    $db->clear;
                    my $i=0;
                    for my $m (__pod_idx $r) {
                        $db->insert([['idx'], pack("N",$i++), $m]);
                    }
                    $db->commit;
                }
            }
        };
        die ref $@ ? ${$@} : $@ if $@;
        $db->datamode=MMapDB::DATAMODE_SIMPLE();
        return wantarray ? @{$db->main_index->{idx}} : undef;
    }

    sub _index {
        my ($r, $force)=@_;

        my @links;
        my $dbfile;
        my $idxkind;

        _reset_link_generator;
        if( defined ($dbfile=$r->dir_config->get('CACHE')) ) {
            @links=map {_link($_, '')} _update_cache $r, $dbfile, $force;
            $idxkind=INDEX_PODCACHED;
        } else {
            @links=map {_link($_, '')} __pod_idx $r;
            $idxkind=INDEX_PODINDEX;
        }

        return (_header($idxkind, _stylesheet($r)).
                _gen_index.
                join("\n", @links)."\n".
                _footer);
    }
}

sub _scanit {
    my ($r, $fun, $where) = @_;
    local $_;

    $fun=~s/%([0-9A-Fa-f]{2})/pack('H2', $1)/eg;
    my $search_re = ($fun=~/^-[rwxoRWXOeszfdlpSbctugkTBMAC]$/
                     ? qr/^=item\s+(?:I<)?-X\b/
                     : $fun=~/^\$[1-9]/
                     ? qr/^=item\s+\$<I<digits>>/
                     : $fun=~/^\$</
                     ? qr/^=item\s+\$<(?!I<digits>>)/
                     : $fun=~/\w$/
                     ? qr/^=item\s+\Q$fun\E\b/
                     : qr/^=item\s+\Q$fun\E/);

    #warn "fun=$fun -- re=$search_re\n";

    my $document='';

    open my $f, '<', _findpod($r, $where, 1) or
        die \Apache2::Const::NOT_FOUND;
    # Skip introduction
    my $anchor=($where eq 'perlvar'
                ? qr/^=over 8/
                : qr/^=head2 Alphabetical Listing of Perl Functions/);
    while( <$f> ) {$_=~$anchor and last}

    # Look for our function
    my $found=0;
    my $inlist=0;
    my $prefix='';

    while( <$f> ) {
        if ( /$search_re/ )  {
            $found = 1;
        } elsif (/^=item/) {
            if ($found > 1 and !$inlist) {
                close $f;
                return "=over 4\n\n$prefix$document\n\n=back\n\n";
            } elsif (!$found and !$inlist) {
                $prefix.=$_."\n";
            }
        } elsif ($found > 1 and !$inlist and /^=back/) {
            close $f;
            return "=over 4\n\n$prefix$document\n\n=back\n\n";
        } elsif (!$found and /\S/) {
            $prefix='';
        }
        next unless $found;
        if (/^=over/) {
            ++$inlist;
        } elsif (/^=back/) {
            --$inlist;
        }
        $document .= "$_";
        ++$found if /^\w/;        # found descriptive text
    }

    die \Apache2::Const::NOT_FOUND;
}

sub _getpodfuncdoc {
    my ($r, $fun) = @_;

    foreach my $name (qw/perlfunc perlvar/) {
        my $doc=eval {_scanit $r, $fun, $name};
        return $doc unless $@;
    }

    die \Apache2::Const::NOT_FOUND;
}

sub _body {
    my ($r, $file, $function, $uplink)=@_;

    my $body;
    my $parser=$r->dir_config('PARSER');
    $parser='Apache2::PodBrowser::Formatter' unless length $parser;
    eval "require $parser";
    if( $@ ) {
        chomp $@;
        $r->log_reason($@);
        die \Apache2::Const::NOT_FOUND;
    }
    $parser=$parser->new;
    $parser->r($r) if ($parser->can('r'));
    $parser->html_css(_stylesheet($r)) if ($parser->can('html_css'));
    $parser->html_header_after_title($parser->html_header_after_title.
                                     _indexlink(INDEX_NORMAL)."\n")
        if ($uplink and $parser->can('html_header_after_title'));
    $parser->no_errata_section(1);
    $parser->complain_stderr(1);
    $parser->output_string( \$body );
    $parser->index( $r->dir_config('INDEX') ) if ($parser->can('index'));
    if ($parser->can('perldoc_url_prefix')) {
        my $prefix=$r->dir_config('LINKBASE');
        if (defined $prefix) {
            $parser->perldoc_url_prefix($prefix);
        } else {
            $parser->perldoc_url_prefix('');
        }
    }
    if ( $function ) {
        $parser->parse_string_document( _getpodfuncdoc($r, $function) );
        $body=~s!<a href="(?:\./perl(?:func|var))?#([^"]+)"!<a href="./?$1"!g;
    } else {
        $parser->parse_file( $file );
    }
    # TODO: Send the timestamp of the file in the header here
    return $body;
}

sub _compress {
    my $r=$_[1];                # do not copy $_[0] here

    if ($r->dir_config('GZIP') and eval {require Compress::Zlib}) {
        $r->headers_out->add(Vary=>'accept-encoding');
        if ($r->subprocess_env->{'no-gzip'} ne '1') { # behave as mod_deflate
            if ($r->headers_in->{'Accept-Encoding'} =~ /\bdeflate\b/) {
                $r->headers_out->{'Content-Encoding'} = 'deflate';
                $r->content_encoding('deflate');
                return Compress::Zlib::compress
                    ($_[0], &Compress::Zlib::Z_BEST_COMPRESSION);
            } elsif ($r->headers_in->{'Accept-Encoding'} =~ /\bgzip\b/) {
                $r->headers_out->{'Content-Encoding'} = 'gzip';
                $r->content_encoding('gzip');
                return Compress::Zlib::memGzip($_[0]);
            }
        }
    }
    return $_[0];
}

sub handler {
    my ($r)=@_;

    my $ct=$r->dir_config('CONTENTTYPE');
    $r->content_type($ct||'text/html');

    my $body;
    eval {
        if( $r->finfo->filetype==APR::Const::FILETYPE_DIR or
            $r->finfo->filetype==APR::Const::FILETYPE_NOFILE ) { # perldoc mode
            # compute sane path_info
            # path_info as it is set by the default map_to_storage
            # handler depends on the directory layout on the disk.
            # In perldoc mode we cannot rely on that. So, we compute
            # saner path_info as the part of the uri that is not covered
            # by $r->location.
            my $loc=$r->location;
            $loc=~s!/+$!!;          # cut off trailing slash;
            $r->path_info(substr($r->uri, length($loc)));
            my $pi=$r->path_info;

            my $pos;
            if ($pi eq '') {
                # issue a redirect to ourself with a trailing slash
                # to generate correct links.
                $r->err_headers_out->{Location}=
                    $r->construct_url($r->uri.'/'.
                                      (length $r->args ? '?'.$r->args : ''));
                die \Apache2::Const::REDIRECT;
            } elsif($pi eq '/-') {
                # update cache and redirect to index.
                _update_cache $r, $r->dir_config->get('CACHE'), 1;
                $r->err_headers_out->{Location}=
                    $r->construct_url(substr($r->uri, 0, -1).
                                      (length $r->args ? '?'.$r->args : ''));
                die \Apache2::Const::REDIRECT;
            } elsif($pi eq '/') {
                if( $r->args ) {    # /perldoc/?FUNCTION
                    if( $r->args eq '?' ) {
                        $body=_compress(_findex($r), $r);
                    } else {
                        $body=_compress(_body($r, undef, $r->args, 1), $r);
                    }
                } else {            # generate index
                    $body=_compress(_index($r), $r);
                }
            } elsif(($pos=index $pi, '/', 1)>0) {
                # image or something like that, e.g.
                #   =for html <img src="Apache2::PodBrowser/img.png">
                my $path=_findpod($r, substr($pi, 1, $pos-1));
                unless( $path=~s!\.[^.]+$!! ) {
                    $path=~s!/[^/]+$!!;
                }
                $path.=substr $pi, $pos;
                update_finfo $r, $path;
                if( $r->finfo->filetype==APR::Const::FILETYPE_REG ) {
                    if( $r->args=~/\bct=([^;&]+)/ ) {
                        # content-type given as URL parameter
                        my $ct=$1;
                        $ct=~s/%([0-9a-f]{2})|\+/defined $1
                                                 ? pack('H2', $1)
                                                 : ' '/egi;
                        $r->content_type($ct);
                    } elsif( substr($path, -4) eq '.png' ) {
                        $r->content_type('image/png');
                    } elsif( substr($path, -4) eq '.jpg' or
                             substr($path, -5) eq '.jpeg' ) {
                        $r->content_type('image/jpeg');
                    } elsif( substr($path, -4) eq '.gif' ) {
                        $r->content_type('image/gif');
                    } elsif( substr($path, -3) eq '.js' ) {
                        $r->content_type('text/javascript');
                    } elsif( substr($path, -4) eq '.pdf' ) {
                        $r->content_type('application/pdf');
                    } elsif( substr($path, -5) eq '.html' ) {
                        $r->content_type('text/html');
                    } else {
                        $r->content_type('application/octet-stream');
                    }
                    $r->set_content_length($r->finfo->size);
                    my $rc=$r->sendfile($path);
                    $rc==APR::Const::SUCCESS or die \$rc;
                    die \Apache2::Const::OK;
                } else {
                    die \Apache2::Const::NOT_FOUND;
                }
            } else {
                my $fn=_findpod($r, $pi);
                update_finfo $r, $fn;
                $body=_compress(_body($r, $fn, undef, 1), $r);
            }
        } else {                    # simple handler
            # here we expect $r->filename to point to a file containing POD
            # and path_info to be empty.
            die \Apache2::Const::NOT_FOUND
                if (length $r->path_info or
                    ($r->finfo->filetype!=APR::Const::FILETYPE_REG));

            update_finfo $r;

            $body=_compress(_body($r, $r->filename, undef, 0), $r);
        }
    };
    # In case of an error we expect $@ to be a reference
    # the points to a scalar containing the HTTP error code
    # If that is not the case the next line will lead to an internal
    # server error which is ok then.
    return Apache2::Const::NOT_FOUND
        if ref $@ eq 'APR::Error' and $@==APR::Const::ENOENT;

    return ${$@} if ref $@ eq 'SCALAR';

    if( $@ ) {
        chomp $@;
        $r->log_reason($@);
        return Apache2::Const::NOT_FOUND;
    }

    $r->set_content_length(length($body));
    $r->print( $body );

    return Apache2::Const::OK;
}

sub Fixup {                     # use a fixup instead of a transhandler here
    my $r = shift;              # so it can be used in a <Location>

    return Apache2::Const::DECLINED unless ($r->uri =~ m!/(\w+).css$!);

    my $name=$1;
    my $css=$INC{"Apache2/PodBrowser.pm"};
    $css=~s!\.pm$!/$name.css!;

    if ($r->dir_config('GZIP')) {
        $r->headers_out->add(Vary=>'accept-encoding');
        if ($r->headers_in->{'Accept-Encoding'}=~/\bgzip\b/ and
            $r->subprocess_env->{'no-gzip'} ne '1' and # behave as mod_deflate
            $r->subprocess_env->{'gzip-only-text/html'} ne '1' and
            -f $css.'.gz') {
            $r->headers_out->{'Content-Encoding'} = 'gzip';
            $r->content_encoding('gzip');
            $r->filename($css.'.gz');
            $r->path_info('');
            $r->handler('default');
            $r->content_type('text/css');
            $r->finfo(APR::Finfo::stat($r->filename, APR::Const::FINFO_NORM,
                                       $r->pool));
            return Apache2::Const::OK;
        }
    }

    if (-f $css) {
        $r->filename($css);
        $r->path_info('');
        $r->handler('default');
        $r->content_type('text/css');
        $r->finfo(APR::Finfo::stat($r->filename, APR::Const::FINFO_NORM,
                                   $r->pool));

        return Apache2::Const::OK;
    }

    return Apache2::Const::DECLINED;
}

{
    package Apache2::PodBrowser::Formatter;

    use strict;
    use base qw/Pod::Simple::HTML/;

    our $VERSION=Apache2::PodBrowser->VERSION;

    @INC{'Apache2/PodBrowser/Formatter.pm'}=1;

    sub new {
        local $Pod::Simple::HTML::Doctype_decl=
            (qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"}.
             qq{ "http://www.w3.org/TR/html4/loose.dtd">\n});

        return shift->SUPER::new(@_);
    }

    sub resolve_pod_page_link {
        my ($I, $to, $sec)=@_;

        $to=~s/::$//s;
        $to=~s/([^A-Za-z0-9\-_.!~*'():])/sprintf("%%%02X", ord $1)/ge;

        return './'.$to.$I->perldoc_url_postfix
            unless length($I->perldoc_url_prefix);

        return $I->perldoc_url_prefix.$to.$I->perldoc_url_postfix;
    }
}

{
    package Apache2::PodBrowser::DirectMode;

    use strict;
    use base qw/Apache2::PodBrowser::Formatter/;

    our $VERSION=Apache2::PodBrowser->VERSION;

    @INC{'Apache2/PodBrowser/DirectMode.pm'}=1;

    sub r {
        my ($I)=@_;

        if( @_>=2 ) {
            $I->{__PACKAGE__.'::r'}=$_[1];
        }
        $I->{__PACKAGE__.'::r'};
    }

    sub resolve_pod_page_link {
        my ($I, $to, $sec)=@_;

        my $r=$I->r;
        my $base=$r->filename;
        substr( $base, -length($r->uri) )='';

        $to=~s!::$!!;
        $to=~s#
                  ::
              |
                  ([^A-Za-z0-9\-_.!~*'()])
              #
                  $1 ? sprintf("%%%02X", ord $1) : '/'
              #gex;
        if( -f $base.'/'.$to.'.pod' ) {
            return '/'.$to.'.pod';
        } elsif( -f $base.'/'.$to.'.pm' ) {
            return '/'.$to.'.pm';
        } elsif( -f $base.'/'.$to.'.pl' ) {
            return '/'.$to.'.pl';
        } else {
            return $I->SUPER::resolve_pod_page_link(@_[1,$#_]);
        }
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Apache2::PodBrowser - show your POD in a browser

=head1 DESCRIPTION

Yet another mod_perl2 handler to view POD in a HTML browser. See L</HISTORY>
for more information.

=head2 Direct Mode

C<Apache2::PodBrowser> can run in I<direct> and I<perldoc> modes. In
direct mode apache takes care of the URI to filename translation. So,
C<< $r->filename >> points to a regular file when the request hits
C<Apache2::PodBrowser>'s handler. Use this mode if your POD files
are installed in one directory tree which is accessible through the WEB
server. You'll perhaps need an additional directory index handler.

=head2 Perldoc Mode

In I<perldoc> mode you specify a C<Location> where the handler resides.
If you append a module name to the location URL as in

  http://localhost/location/Apache2::PodBrowser

you'll get its documentation.

Further, in perldoc mode you can ask for documentation for a given
perl function similar to C<perldoc -f open> at the command line. Simply
call the location and give the wanted function as CGI keyword:

  http://localhost/location/?open

The same works also for special variables. Try

  http://localhost/location/?$_

and you'll see the documentation for C<$_>.

Usually you want to use perldoc mode. It allows you to access PODs
at their natural locations. On the downside, it is of
course a bit slower.

=head2 Indexes

Also in perldoc mode, there are 2 indexes available, one of all installed
modules and scripts that come with POD and one of built-in functions and
variables.

The the handler location itself shows the module index:

  http://localhost/location/

If a single question mark C<?> is given as CGI keyword the function and
variable index is shown:

  http://localhost/location/??

Don't worry you don't have to remember all these URLs. The pages are
properly linked together.

=head1 CONFIGURATION

=head2 Direct Mode

Direct mode's basic configuration look like this:

  <Directory /...>
      Options +Indexes
      <Files ~ "\.p(od|m|l)">
          SetHandler modperl
          PerlResponseHandler Apache2::PodBrowser
          PerlSetVar  STYLESHEET /path/to/style.css
          PerlSetVar  PARSER Apache2::PodBrowser::DirectMode
      </Files>
  </Directory>

All F<*.pod>, F<*.pm> and F<*.pl> files will magically be converted to HTML.

=head2 Perldoc Mode

For perldoc mode add the following lines to your F<httpd.conf>:

  <Location /perldoc>
      SetHandler  modperl
      PerlHandler Apache2::PodBrowser
      PerlFixupHandler Apache2::PodBrowser::Fixup
      PerlSetVar  STYLESHEET fancy
  </Location>

You can then get documentation for module C<Apache2::PodBrowser> at
L<http://localhost/perldoc/Apache2::PodBrowser>.

Finally, a particular Perl built-in function's or variable's documentation
is at L<http://localhost/perldoc/?function_or_variable_name>. For example
L<http://localhost/perldoc/?open> or L<http://localhost/perldoc/?$_>.

At L<http://localhost/perldoc/> you'll see a module index and at
L<http://localhost/perldoc/??> an index over all built-in functions and
variables.

=head2 Configuration Variables

The following variables affect the work of C<Apache2::PodBrowser>.
They are all set by C<PerlSetVar> or C<PerlAddVar>. See
F<t/conf/extra.conf.in> for example configurations.

=head3 STYLESHEET

Specifies the stylesheet to use with the output HTML file.

  PerlSetVar  STYLESHEET /path/to/style.css

There are 2 stylesheets I<auto> and I<fancy> that come with this
module. They are installed alongside in C<@INC>. To use them either
teach your Apache to look for them or use the provided fixup handler:

  PerlFixupHandler Apache2::PodBrowser::Fixup
  PerlSetVar STYLESHEET fancy    # or auto

If you want to use your own stylesheet simply specify its URL.

To use one of the built in styles in direct mode you have to teach
apache where it is located. One way is to use an C<Alias> and make
the file accessible. Another is to use the provided fixup handler.
For example

  <Directory /some/directory>
      Options +Indexes
      <Files ~ "\.p(od|m)">
          SetHandler modperl
          PerlResponseHandler Apache2::PodBrowser
          PerlSetVar STYLESHEET /auto.css
          PerlSetVar PARSER Apache2::PodBrowser::DirectMode
      </Files>
      <Files *.css>
          PerlFixupHandler Apache2::PodBrowser::Fixup
      </Files>
  </Directory>

In direct mode the stylesheet must be given as a complete URL not just
C<auto> or C<fancy>.

=head3 INDEX

When INDEX is true, a table of contents is added at the top of the
HTML document.

  PerlSetVar INDEX 1

By default, this is off.

The C<fancy> stylesheet places the index into a sort of drop-down menu
that is placed fixed at the right top corner of the page. So, it is always
at hand if you want to jump to another part of the document. This works
in most browsers with the necessary CSS support. Notably, the Internet
Explorer is not among them.

=head3 GZIP

When GZIP is true, the whole HTTP body is compressed. The browser must
accept gzip, and L<Compress::Zlib> must be available. Otherwise, GZIP is
ignored.

An appropriate C<Vary> header is issued to make proxy servers happy.

Also the environment variables C<no-gzip> and C<gzip-only-text/html>
that can be set for example by the C<BrowserMatch> directive are regarded.
See L<the mod_deflate documentation
|http://httpd.apache.org/docs/2.2/mod/mod_deflate.html#recommended> for
more information

  PerlSetVar GZIP 1

By default, this is off.

=head3 PODDIR

This variable is useful only in perldoc mode.

It declares additional directories to look for PODs. This can be given multiple
times. Directories given this way are searched B<before> C<@INC>.

  PerlAddVar PODDIR /path/to/project1
  PerlAddVar PODDIR /path/to/project2

=head3 NOINC

In perldoc mode POD files are normally looked up in C<@INC> plus in the
directories given by C<PODDIR>. If C<NOINC> is set then the C<@INC> search
is skipped. That means only the directories specifed in F<httpd.conf>
are scanned:

  PerlAddVar NOINC 1

For documentation requests for perl functions via
L<http://localhost/perldoc/?functionname> C<@INC> is used nevertheless
to locate C<perlfunc.pod> if it is not found in one of the given directories.

In direct mode this variable is ignored.

=head3 CACHE

When in perldoc mode C<Apache2::PodBrowser> uses
L<Pod::Find::pod_find>
to generate a list of available POD files. This may take quite a while
depending upon the number of directories and files to scan for POD.

To avoid to repeat this for each POD index request one can set up a cache.

  PerlSetVar CACHE /path/to/cache.mmdb

The cache file itself is created on the first access to the index. The POD
index page then contains a link to update the cache. So, if a POD file
is added or removed from the system this link is to be clicked to keep
the POD index page up to date.

The cache file itself is a L<MMapDB> object. If this module is not available
you'll probably get a C<404 - NOT FOUND> response the next time the POD index
page is requested if C<CACHE> is set.

The directory containing the cache file must be writable by the C<httpd>.

=head3 CONTENTTYPE

You'll probably need that only for plain text output with the
L<Pod::Simple::Text> parser. Here one can set the content type
of the output.

  PerlSetVar CONTENTTYPE "text/plain; charset=UTF-8"

=head3 PARSER and LINKBASE

C<PARSER> sets the POD-to-HTML converter class that is used. It should
support at least the interface that L<Pod::Simple::Text> provides.

The L<Pod::Simple::Text> parser gives you plain text.

If L<Pod::Simple::HTML> is used as parser one gets almost usable output
except for the missing C<DOCTYPE> HTML header and the broken linkage
to other modules.

The default C<PARSER> is C<Apache2::PodBrowser::Formatter> and is
suitable for perldoc mode. It derives
from L<Pod::Simple::HTML> but overrides the constructor C<new> to
provide a C<DOCTYPE> and C<resolve_pod_page_link> to fix the linkage.

If C<LINKBASE> is not set or empty C<resolve_pod_page_link> creates
relative links to other modules of the type:

  ./Other::Module

If C<LINKBASE> is set it is prepended before C<Other::Module> instead
of C<./>. For example you could set

  PerlSetVar LINKBASE http://search.cpan.org/perldoc?

to generate links to CPAN.

For perldoc mode an empty C<LINKBASE> is best choice.

In direct mode an other parser C<Apache2::PodBrowser::DirectMode> should
be used. It derives from C<Apache2::PodBrowser::Formatter> but overrides
C<resolve_pod_page_link>.

This time the link generator searches for the link destination POD by
the module name with one of the following extensions appended: C<.pod>,
C<.pm> and C<.pl>. If none is found it resorts to its base class. And
now C<LINKBASE> makes sense.

If you know of a C<Apache2::PodBrowser> running in perldoc mode you can
point C<LINKBASE> to that address. This way modules that does not exist
in the local tree would be looked up there or on CPAN if C<LINKBASE>
points there.

If all that is unsuitable for you you can implement your own C<PARSER>
class. Have a look at the source code of this module. It is quite straight
forward regarding the 2 parser classes.

=head2 The Fixup Handler

If you use your own stylesheet or teach apache to find one of the
provided styles in the file system you don't need the fixup handler.

It simply does the file lookup for you.

If you don't like it just find the style sheet in your file system:

  find $(perl -e 'print "@INC"') -type f -name fancy.css

copy it into your C<DocumentRoot> and set C<STYLESHEET> to find it.

=head1 WHISHLIST

=over 4

=item * speed up POD index generation

=back

=head1 HISTORY

As you may know there is already L<Apache2::Pod::HTML>. This module
has borrowed some ideas from it but is implemented anew. In fact, I
had started by editing L<Apache2::Pod::HTML> 0.27 but at a certain moment
I had patched it into something that only vaguely remembered the
original code. When the HTML functionality
was ready I discovered that L<Apache2::Pod::Text> had also to be
taken care of. That was too much to bear.

=head2 Differences from Apache2::Pod::HTML as of version 0.01

=over 4

=item * POD index

an index of all PODs found in the given scan directories is
returned if the handler is called in C<perldoc> mode without
a module argument.

=item * NOINC variable

=item * PODDIR variable

=item * PARSER variable

=item * CONTENTTYPE variable

new configuration variables

=item * proper HTTP protocol handling

L<Apache2::Pod::HTML> does not issue a C<Vary> HTTP header in GZIP mode.
It does not support turning off GZIP for certain browsers by C<BrowserMatch>.
And it does not sent C<Content-Length>, C<Last-Modified> or C<ETag> headers.

C<Apache2::PodBrowser> issues correct headers when GZIP is on. It also
sends C<ETag>, C<Last-Modified> and C<Content-Length> headers. And it
checks if a conditional GET request meets its conditions and answers with
HTTP code C<304> (NOT MODIFIED) if so.

=item * using CGI keywords instead of C<PATH_INFO>

how to pass function names to the handler in C<perldoc -f> mode

=item * proper HTTP error codes

L<Apache2::Pod::HTML> returns HTTP code C<200> even if there is no
POD found by a given name

=item * CSS: fancy stylesheet

C<Apache2::PodBrowser> comes with 2 stylesheets, see above

=item * CSS: sent by default handler

C<Apache2::PodBrowser> uses a fixup handler to reconfigure apache
to ship included stylesheets by it's default response handler.

=item * much better test suite

C<Apache2::PodBrowser> uses the L<Apache::Test> framework to test its
work. L<Apache2::Pod::HTML> tests almost only the presence of POD.

=back

=head1 Embedding HTML in POD

=begin html

<div style="width: 80px; height: 104px; background-color: #fff;
            float: right;">
<img align="right"
     alt="Picture of Torsten Foertsch"
     src="Apache2%3A%3APodBrowser/torsten-foertsch.jpg"
     border="0">
</div>

=end html

POD provides the

 =begin html
 ...
 =end html

or

 =for html ...

syntax. This module supports it. If you look at this document via this
module you'll probably see a picture of me on the right side.

Example:

 =begin html

 <img align="right"
      alt="Picture of ..."
      src="http://host.name/image.jpg"
      border="0">

 =end html

You might notice that the image URL is absolute. Wouldn't it be good to
bundle the images with the module, install them somewhere beside it in
C<@INC> and reference them relatively?

It is possible to do that in perldoc mode.
Just strip off the C<.pm> or C<.pod> suffix
from the installed perl module file name and make a directory with that
name. For example assuming that this module is installed as:

 /perl/lib/Apache2/PodBrowser.pm

create the directory

 /perl/lib/Apache2/PodBrowser

and place the images there.

To include them in POD write:

 =begin html

 <img align="right"
      alt="Picture of ..."
      src="./Apache2::PodBrowser/torsten-foertsch.jpg"
      border="0">

 =end html

If the POD file name doesn't contain a dot (C<.>) the last path component
is stripped off to get the directory name.

Note that you need to write the package name again. You also need to
either escape the semicolons as in
C<src="Apache2%3A%3APodBrowser/torsten-foertsch.jpg"> or put a C<./>
in front of the link.

A note about the content type of linked documents. C<Apache::PodBrowser>
does not enter a new request cycle to ship these documents. So, the normal
Apache Content-Type guessing does not take place. C<Apache::PodBrowser> knows
a few file name extensions (C<png>, C<jpg>, C<jpeg>, C<gif>, C<js>,
C<pdf> and C<html>). For those it sends the correct Content-Type headers.
All other documents are shipped as C<application/octet-stream>.

If a document needs a different Content-Type header it can be passed as
CGI parameter:

 src="Apache2%3A%3APodBrowser/torsten-foertsch.jpg?ct=text/plain"

The link above will ship the image as C<text/plain>.

=head1 SEE ALSO

=over 4

=item L<Apache2::Pod::HTML>

=item L<Pod::Simple>

=item L<Pod::Simple::HTML>

=item L<Pod::Simple::Text>

=back

=head1 AUTHOR

Torsten Förtsch C<< <torsten.foertsch@gmx.net> >>

=head1 LICENSE

This package is licensed under the same terms as Perl itself.

=cut
