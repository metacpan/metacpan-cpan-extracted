
package CGI::RSS;

use strict;
use Date::Manip;
use AutoLoader;
use CGI;
use Carp;
use Scalar::Util qw(blessed);
use base 'Exporter';
use vars qw'@TAGS @EXPORT_OK %EXPORT_TAGS';

no warnings;

our $VERSION = '0.9660';
our $pubDate_format = '%a, %d %b %Y %H:%M:%S %z';

# Make sure we have a TZ
unless( eval {Date_TimeZone(); 1} ) {
    $ENV{TZ} = "UTC" if $@ =~ m/unable to determine Time Zone/i;
}

sub pubDate_format {
    my $class_or_instance = shift;
    my $proposed = shift;

    $pubDate_format = $proposed;
    $pubDate_format
}

sub grok_args {
    my $this  = blessed($_[0]) ? shift : __PACKAGE__->new;
    my $attrs = ref($_[0]) eq "HASH" ? shift : undef;

    if( ref($_[0]) eq "ARRAY" ) {
        return ($this,$attrs,undef,$_[0]);
    }

    return ($this,$attrs,join(" ", @_),undef);
}

sub setup_tag {
    my $tag = shift;

    # try to mimick CGI.pm (which is very unfriendly about new tags now)

    no strict 'refs';

    my @these_tags = ($tag, "start_$tag", "end_$tag");

    push @EXPORT_OK, @these_tags;
    push @{ $EXPORT_TAGS{all}  }, @these_tags;
    push @{ $EXPORT_TAGS{tags} }, $tag;

    *{ __PACKAGE__ . "::$tag" } = sub {
        my ($this, $attrs, $contents, $subs) = grok_args(@_);
        my $res;

        if( $subs ) {
            $res = join("", map { $this->$tag( ($attrs ? $attrs : ()), $_ ) } @$subs );

        } else {
            $res = "<$tag";

            if( $attrs ) {
                for(values %$attrs) {
                    # XXX: this is a terrible way to do this, better than nothing for now
                    s/(?<!\\)"/\\"/g;
                }

                $res .= " " . join(" ", map {"$_=\"$attrs->{$_}\""} keys %$attrs);
            }

            $res .= ">$contents</$tag>";
        }

        return $res;
    };

    *{ __PACKAGE__ . "::start_$tag" } = sub {
        my ($this, $attrs) = grok_args(@_);
        my $res = "<$tag";

        if( $attrs ) {
            for(values %$attrs) {
                # XXX: this is a terrible way to do this, better than nothing for now
                s/(?<!\\)"/\\"/g;
            }

            $res .= " " . join(" ", map {"$_=\"$attrs->{$_}\""} keys %$attrs);
        }

        return $res . ">";
    };

    *{ __PACKAGE__ . "::end_$tag" } = sub { "</$tag>" };
}

sub AUTOLOAD {
    my $this = shift;
    our $AUTOLOAD;

    if( my ($fname) = $AUTOLOAD =~ m/::([^:]+)$/ ) {
        if( CGI->can($fname) ) {
            *{ __PACKAGE__ . "::$fname" } = sub {
                my $this = shift;
                return CGI->$fname(@_);
            }
        }

        else {
            croak "can't figure out what to do with $fname() call";
        }
    }
}

sub new {
    my $class = shift;
    my $this = bless {}, $class;

    return $this;
}

sub date {
    my $this = shift;

    if( my $pd = ParseDate($_[-1]) ) {
        my $date = UnixDate($pd, $pubDate_format);
        return $this->pubDate($date);
    }

    $this->pubDate(@_);
}

sub header {
    my $this = shift;

    my $charset = "UTF-8";
    my $mime    = "application/xml";

    eval {
        no warnings;
        local $SIG{WARN} = sub{};
        my %opts = @_;
        $charset = $opts{'-charset'} || $opts{charset} || $charset;
        $mime    = $opts{'-type'} || $opts{type} || (@_==1 && $_[0]) || $mime;
    };

    return CGI::header(-type=>$mime, -charset=>$charset) . "<?xml version=\"1.0\" encoding=\"$charset\"?>\n\n";
}

sub begin_rss {
    my $this = shift;
    my $opts = $_[0];
       $opts = {@_} unless ref $opts;

    # NOTE: This isn't nearly as smart as CGI.pm's argument parsing... 
    # I assume I could call it, but but I'm only mortal.

    my $ver = $opts->{version} || "2.0";
    my $ret = $this->start_rss({version=>$ver});
       $ret .= $this->start_channel;
       $ret .= $this->link($opts->{link})        if exists $opts->{link};
       $ret .= $this->title($opts->{title})      if exists $opts->{title};
       $ret .= $this->description($opts->{desc}) if exists $opts->{desc};

    return $ret;
}

sub finish_rss {
    my $this = shift;

    return $this->end_channel . $this->end_rss;
}

BEGIN {
    @TAGS = qw(
        rss channel item

        title link description

        language copyright managingEditor webMaster pubDate lastBuildDate category generator docs
        cloud ttl image rating textInput skipHours skipDays

        link description author category comments enclosure guid pubDate source

        pubDate url
    );

    setup_tag($_) for @TAGS;
}

1;

__END__
