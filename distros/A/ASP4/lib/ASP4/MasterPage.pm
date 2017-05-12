
package ASP4::MasterPage;

use strict;
use warnings 'all';
use base 'ASP4::Page';

1;# return true:

=pod

=head1 NAME

ASP4::MasterPage - Root class for MasterPage classes.

=head1 SYNOPSIS

In your ASP script (C</eg-master.asp>):

  <%@ MasterPage %>
  <html>
    <body>
      <h1><asp:ContentPlaceHolder id="heading">Default Heading</asp:ContentPlaceHolder></h1>
      <p>
        <asp:ContentPlaceHolder id="content">Default Content</asp:ContentPlaceHolder>
      </p>
    </body>
  </html>

It gets compiled down to:

  package MyApp::_eg_master_asp;

  use strict;
  use warnings 'all';
  no warnings 'redefine';
  use base 'ASP4::MasterPage';
  use vars __PACKAGE__->VARS;
  use ASP4::PageLoader;

  sub _init {
    my ($s) = @_;
    $s->{script_name} = q</eg-master.asp>;
    $s->{filename}    = q</home/john/Projects/www.example.com/htdocs/eg-master.asp>;
    $s->{base_class}  = q<ASP4::MasterPage>;
    $s->{compiled_as} = q<MyApp/_eg_master_asp.pm>;
    $s->{package}     = q<MyApp::_eg_master_asp>;

    return;
  }

  sub run {
  use warnings 'all';
  my ($__self, $__context) = @_;
  #line 1
  ;$Response->Write(q~
  <html>
    <body>
      <h1>~); $__self->heading($__context); $Response->Write(q~</h1>
      <p>
        ~); $__self->content($__context); $Response->Write(q~
      </p>
    </body>
  </html>
  ~);
  }

  sub heading {
  my ($__self, $__context) = @_;
  #line 4
  $Response->Write(q~Default Heading~);
  }# end heading

  sub content {
  my ($__self, $__context) = @_;
  #line 6
  $Response->Write(q~Default Content~);
  }# end content

  1;# return true:

Which, when executed, produces:

  <html>
    <body>
      <h1>Default Heading</h1>
      <p>
        Default Content
      </p>
    </body>
  </html>

=head2 But Wait - There's More!

MasterPages only get interesting when we add "child" pages to them:

(C</eg-child.asp>)

  <%@ Page UseMasterPage="/eg-master.asp" %>

  <asp:Content PlaceHolderID="heading">New Heading</asp:Content>

  <asp:Content PlaceHolderID="content">New Content</asp:Content>

Which compiles down to:

  package MyApp::_eg_child_asp;

  use strict;
  use warnings 'all';
  no warnings 'redefine';
  use base 'MyApp::_eg_master_asp';
  use vars __PACKAGE__->VARS;
  use ASP4::PageLoader;

  sub _init {
    my ($s) = @_;
    $s->{script_name} = q</eg-child.asp>;
    $s->{filename}    = q</home/john/Projects/www.example.com/htdocs/eg-child.asp>;
    $s->{base_class}  = q<MyApp::_eg_master_asp>;
    $s->{compiled_as} = q<MyApp/_eg_child_asp.pm>;
    $s->{package}     = q<MyApp::_eg_child_asp>;
    $s->{masterpage}  = ASP4::PageLoader->load( script_name => q</eg-master.asp> );
    return;
  }

  sub heading {
  my ($__self, $__context) = @_;
  #line 3
  $Response->Write(q~New Heading~);
  }# end heading

  sub content {
  my ($__self, $__context) = @_;
  #line 5
  $Response->Write(q~New Content~);
  }# end content

  1;# return true:

And when executed produces:

  <html>
    <body>
      <h1>New Heading</h1>
      <p>
        New Content
      </p>
    </body>
  </html>

=head2 And Even More!

Child pages can also be master pages:

(C</eg-subpage.asp>):

  <%@ MasterPage %>
  <%@ Page UseMasterPage="/eg-master.asp" %>

  <asp:Content PlaceHolderID="heading">New Heading</asp:Content>

  <asp:Content PlaceHolderID="content">
    New Content
    <span id="copyright">
      Copyright
      <asp:ContentPlaceHolder id="copyright"></asp:ContentPlaceHolder>: 
      All Rights Reserved
    </span>
  </asp:Content>

And inherited from again:

(C</eg-subchild.asp>):

  <%@ Page UseMasterPage="/eg-master.asp" %>

  <asp:Content PlaceHolderID="copyright">SuperMegaCorp, Inc.</asp:Content>

Which - when executed, produces:

  <html>
    <body>
      <h1>New Heading</h1>
      <p>
        
    New Content
    <span id="copyright">
      Copyright
      SuperMegaCorp, Inc.:
      All Rights Reserved
    </span>

      </p>
    </body>
  </html>

=head1 DESCRIPTION

MasterPages provide a means of rich page composition.  This means that instead
of a tangle of server-side includes, you can actually take advantage of this 
new concept (came out decades ago) called "class inheritance" - and apply it
to your web pages.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

