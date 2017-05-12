package CGI::Pager;

use 5.008;
use strict;
use warnings;

use URI;
use URI::QueryParam;


our $VERSION = '1.00';


sub new {
   ## The constructor
   my $proto = shift;

   my $self = bless {
      url              => $ENV{REQUEST_URI},
      offset_param     => 'offset',
      hide_zero_offset => 1,
      page_len         => 20,
      labels => {
         first => 'First',
         last  => 'Last',
         next  => 'Next',
         prev  => 'Previous',
      },
      links_order => [ qw/first prev pages next last/ ],
      links_delim => ' &nbsp; ',
      pages_delim => '  ',
      @_,
   }, $proto;

   $self->{URI} = URI->new($self->{url});
   $self->{offset} = $self->{URI}->query_param($self->{offset_param}) || 0;

   return $self;
}


sub url_for_offset {
   ## Returns URL for the given offset.
   my $self = shift;
   my ($offset) = @_;

   return undef unless defined $offset;

   my $work_uri = $self->{URI}->clone;

   if ($offset == 0 && $self->{hide_zero_offset}) {
      $work_uri->query_param_delete($self->{offset_param});
   }
   else {
      $work_uri->query_param($self->{offset_param} => $offset);
   }

   return $work_uri;
}


sub total_count {
   ## Return total count of results, as set on initialization.
   my $self = shift;

   return $self->{total_count};
}


sub is_at_start {
   ## Returns true if the pager is at the start of recordset.
   my $self = shift;

   return !$self->{offset};
}


sub is_at_end {
   ## Returns true if the pager is at the end of recordset.
   my $self = shift;

   return $self->{offset} + $self->{page_len} >= $self->{total_count};
}


sub next_offset {
   ## Returns offset for the next page.
   my $self = shift;

   return $self->is_at_end ? undef : $self->{offset} + $self->{page_len};
}


sub prev_offset {
   ## Returns offset for the previous page.
   my $self = shift;

   return undef if $self->is_at_start;

   my $prev_offset = $self->{offset} - $self->{page_len};
   $prev_offset = 0 if $prev_offset < 0;

   return $prev_offset;
}


sub last_offset {
   ## Returns offset for the last page.
   my $self = shift;

   my $last_page_len = ($self->{total_count} % $self->{page_len})
                       || $self->{page_len};
   my $last_offset = $self->{total_count} - $last_page_len;
   $last_offset = 0 if $last_offset < 0;

   return $last_offset;
}


sub first_pos_displayed {
   ## Returns position of the first row currently displayed.
   my $self = shift;

   return $self->{offset} + 1;
}


sub last_pos_displayed {
   ## Returns position of the last row currently displayed.
   my $self = shift;

   my $result = $self->{offset} + $self->{page_len};
   $result = $self->{total_count} if $result > $self->{total_count};

   return $result;
}


sub prev_url {
   ## Returns URL for the previous page as URI object.
   my $self = shift;

   return $self->url_for_offset($self->prev_offset);
}


sub next_url {
   ## Returns URL for the next page as URI object.
   my $self = shift;

   return $self->url_for_offset($self->next_offset);
}


sub first_url {
   ## Returns URL for the first page as URI object.
   my $self = shift;

   return $self->url_for_offset(0);
}


sub last_url {
   ## Returns URL for the last page as URI object.
   my $self = shift;

   return $self->url_for_offset($self->last_offset);
}


sub pages {
   ## Returns reference to an array of hashes representing pages in
   ## the result set.
   my $self = shift;

   unless ($self->{pages}) {

      my $offset = 0;
      my $page_num = 1;

      do {
         push @{ $self->{pages} }, {
            url        => $self->url_for_offset($offset),
            number     => $page_num,
            offset     => $offset,
            is_current => $offset == $self->{offset},
         };

         $offset += $self->{page_len};
         $page_num++;

      } while ($offset < $self->{total_count});
   }

   return wantarray ? @{ $self->{pages} } : $self->{pages};
}


sub html {
   ## Returns HTML for specified part(s) of navigation.
   my $self = shift;
   my ($format) = @_;

   if ($format eq 'combined_div') {
      return @{ $self->pages } > 1 ?
                '<div class="navBar">' . $self->html('combined') . '</div>' : '';
   }
   elsif ($format eq 'combined') {
      return join $self->{links_delim},
                  grep defined,
                       map $self->html($_),
                           @{ $self->{links_order} };
   }
   elsif ($format eq 'pages') {
      return join $self->{pages_delim},
                  map $_->{is_current} ?
                         "<strong>$_->{number}</strong>" :
                         "<a href=\"$_->{url}\">$_->{number}</a>",
                      $self->pages;
   }
   else {
      return undef if $format =~ /^(first|prev)$/ && $self->is_at_start
                      || $format =~ /^(last|next)$/ && $self->is_at_end;
      my $url_method = "${format}_url";
      return '<a href="'. $self->$url_method . "\">$self->{labels}{$format}</a>";
   }
}


sub quick_html {
   ## Returns HTML generated by automatically created pager instance.
   ## Designed to be called as function instead of OO interface.
   my %params = @_;

   my $html_mode = delete $params{html_mode};
   my $pager = __PACKAGE__->new(%params);
   return $pager->html($html_mode);
}


1;


__END__

=head1 NAME

CGI::Pager - generate HTML pagination linkage easily.

=head1 ABSTRACT

Generates helper data and HTML for paginated representation of results.

=head1 SYNOPSIS

=head2 Using with CGI.pm:

  my $pager = CGI::Pager->new(
     total_count => $search_results_count,
     page_len    => 50,
  );

  print 'Found ', $search_results_count, ' results, displaying: ',
         $pager->first_pos_displayed, ' - ', $pager->last_pos_displayed, ' ';

  # Display links to first and previous page, if necessary.
  unless ($pager->is_at_start) {
     print a({ -href => $pager->first_url }, 'First page'), ' ',
           a({ -href => $pager->prev_url }, '<< Previous page');
  }

  # Display links to each individual page of results.
  foreach my $page ($pager->pages) {
     if ($page->{is_current}) {
        print strong($page->{number});
     }
     else {
        print a({ -href => $page->{url} }, $page->{number});
     }
  }

  # Display links to next and the last page, if necessary.
  unless ($pager->is_at_end) {
     print a({ -href => $pager->next_url }, 'Next page >>'), ' ',
           a({ -href => $pager->last_url }, 'Last page');
  }


=head2 Specifying custom parameters, combining templating system and
built-in HTML generation:

  my $pager = CGI::Pager->new(
     labels => {
        first => 'First',
        last  => 'Last',
        next  => 'Next',
        prev  => 'Previous',
     },
     links_order => [ qw/first prev pages next last/ ],
     links_delim => ' &nbsp; | &nbsp; ',
     pages_delim => ' ',
  );

  $template->param(
     first_page_url => $pager->first_url,
     prev_page_url  => $pager->prev_url,
     next_page_url  => $pager->next_url,
     last_page_url  => $pager->last_url,
     page_links     => $pager->html('pages'),
  );

=head2 Functional style, built-in HTML generation:

 print CGI::Pager::quick_html(
    total_count => $search_results_count,
    page_len    => 50,
    html_mode   => 'combined',
 );


=head1 DESCRIPTION

CGI::Pager performs the "dirty work" necessary to program paginated
data display in a web application. Based on given resultset size,
page size, and offset value sensed from current URI, it constructs
links for navigation between results pages. It can be used
conveniently from a templating system, has both OO and functional
interface, and can optionally generate necessary HTML itself.

=head2 METHODS

=over 2

=item B<new(%parameters)>

The constructor, accepting named configuration parameters.
See L</PARAMETERS> below.

=item B<is_at_start, is_at_end>

Return true if the pager is at the start or the end of recordset
respectively.

=item B<next_offset, prev_offset, last_offset>

Return offset value the respective pages. If there's a bounds conflict,
like when you call B<prev_offset> while on the first page, undef is
returned.

=item B<first_pos_displayed, last_pos_displayed>

Return the position (starting from 1) of the first or last row
respectively, displayed on current page.

=item B<first_url, prev_url, next_url, last_url>

Return URLs of the respective pages as URI objects. Bounds conflicts
are handled like in the above family of methods.

=item B<total_count>

Return total count of results, as set on initialization.

=item B<pages>

Returns reference to an array of hashes representing pages in
the result set. The hashes have following keys: C<url> - the URL
of the page, C<number> - the number of page, starting from 1,
and C<is_current> - true if page is the currently displayed page.

=item B<html($mode)>

Returns HTML string with navigational links according to $mode, which
can be: C<first>, C<last>, C<prev>, C<next>, C<pages>, C<combined> or
C<combined_div>.  The first four will produce a single link to
respective page. 'pages' yields a string of links to individual
pages. C<combined>, which is the default, is concatenation of
these. C<combined_div> is like C<combined>, but wrapped in a DIV
element with class attribute set to "navBar". The concatenation of
links can be controlled by C<links_order>, C<links_delim> and
C<pages_delim> initialization parameters.

=item B<quick_html(%params)>

Not a method, but function, designed to be called as
C<CGI::Pager::quick_html>. Returns HTML generated by internally
created temporary pager instance. Made for those rare cases when not
using OO style is cleaner. Accepted parameters are the same as for
constructor, except with the extra C<html_mode> which works like the
C<$mode> parameter of C<html> method.

=back

=head2 PARAMETERS

All options are given as named parameters to constructor (when using OO
style) and aren't then changeble - a CGI::Pager instance is not meant
to persist between requests. Below is a list of valid options:

=over 2

=item * C<total_count>

The size of your recordset. This is the only mandatory option.

=item * C<page_len>

The number of items displayed per page. Default is 20.

=item * C<offset_param>

The name of the GET request variable holding current offset within the
resultset. Defaults to 'offset'. Change if you name your variable
differently.

=item * C<hide_zero_offset>

If true (default), generated URL of the first page will not contain
the offset parameter (like, '&offset=0'.) This is what you want in
most cases.

=item * C<url>

Specifies the base URL, which will be used to produce URLs in all
links, generated by this module. Defaults to value of
C<$ENV{REQUEST_URI}>, which should be fine in most web application
environments.

=item * C<labels>

Content to place inside generated links. Can be arbitary text or
HTML. Given as a hash reference, see L<"SYNOPSIS"> for explanatory example,
which also shows default values.

=item * C<links_order>

In what order navigational links will be placed, when generating HTML
in 'combined' format. For example/defaults, see the above.

=item * C<links_delim>

Delimiter used to space ordinary links (i.e, 'First', 'Previous', etc)
when generating HTML in 'combined' format. Defaults to ' &nbsp; '.

=item * C<pages_delim>

Delimiter used to space individual page links. Defaults to ' '.

=back

=head2 NOTES

This module operates on the assumption that current offset is passed
as a GET request variable (except that for the first page, where it's
OK for it to be absent.)

An instance of CGI::Pager is meant to last only for the duration of
the request and isn't designed to be reused, like one might try in a
mod_perl environment.


=head1 SEE ALSO

L<URI::QueryParam>

=head1 AUTHOR

Egor Shipovalov, L<http://pragmaticware.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Egor Shipovalov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
