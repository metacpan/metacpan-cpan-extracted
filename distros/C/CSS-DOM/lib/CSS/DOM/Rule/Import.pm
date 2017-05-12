package CSS::DOM::Rule::Import;

$VERSION = '0.16';

use warnings; no warnings qw 'utf8 parenthesis';
use strict;

use CSS::DOM;
use CSS::DOM::Exception qw/ SYNTAX_ERR /;
 use        CSS::DOM::Rule;

our @ISA = 'CSS::DOM::Rule';

use constant 1.03 our $_const = {
# Don't let this conflict with the superclass.
	hrfe => 2,
	medi => 3,
	shet => 4,
	urlt => 5, # url token
};
{ no strict; delete @{__PACKAGE__.'::'}{_const => keys %{our $_const}} }


# overrides:
sub type { CSS::DOM::Rule::IMPORT_RULE }
sub cssText {
	my $self = shift;
	my $old;
	if(defined wantarray) {
		$old = "\@import $self->[urlt][1]" . (
			$self->[medi] ? ' '.$self->[medi]->mediaText : ''
		) . ";\n";
	}
	if (@_) {
		@$self[hrfe,medi,shet,urlt] =
			@{$self->_parse(shift)}[hrfe,medi,shet,urlt];
#use DDS; Dump $self;
	}
	$old;
};


# CSSImportRule interface:

sub href {
	my $self =shift;
	$self->[hrfe] ||= do {
		require CSS'DOM'Parser;
		if($self->[urlt][00] eq 'u') {
			# ~~~ I probably ought to put things like this in a
			#     Parser::token_val function.
			my $url = $self->[urlt][1];
			$url =~ s/^url\([ \t\r\n\f]*//;
			$url =~ s/[ \t\r\n\f]*\)\z//;
			$url =~ s/^['"]// and chop $url;
			CSS'DOM'Parser'unescape($url);
		}
		else {
			CSS'DOM'Parser'unescape(
				substr $$self[urlt][1], 1, -1
			)
		}
	}
}
sub _set_url_token {
	for(shift) {
		delete $_->[hrfe];
		$_->[urlt] = \@_;
	}
}

sub media {
	wantarray ? @{$_[0]->[medi]||return} :
		($_[0]->[medi] ||= (
			require CSS::DOM::MediaList,
			CSS::DOM::MediaList->new
		))
}

sub styleSheet{
	# I use 0 instead of undef for a non-existent style sheet. undef is
	# used to mean that we haven’t even  considered  loading  it  yet.
	# Using existence of the element as the criterion makes the code
	# too unmaintainable.
	my $self = shift;
	unless( defined($self->[shet])) {
		my $fetcher = $self->parentStyleSheet->url_fetcher;
		# ~~~ What do we do about the charset?
		my($css,@args);
		($css,@args) = $fetcher->($self->href) if defined $fetcher;
		defined $css or $self->[shet]=0, return;		
		require CSS::DOM::Parser;
		for(($self->[shet] =
		         eval{CSS::DOM::Parser::parse($css,@args)}||0)
		    || return){
			$_->_set_ownerRule($self);
			if(my$parent=$self->parentStyleSheet){
				$_->_set_parentStyleSheet($parent);
				$_->url_fetcher($parent->url_fetcher);
			}
			return $_;
		}
	}
	return $self->[shet]||();
}

                              !()__END__()!

=head1 NAME

CSS::DOM::Rule::Import - CSS @import rule class for CSS::DOM

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

  use CSS::DOM;
  my $import_rule = CSS::DOM->parse(
      '@import "print.css" print;',
      url_fetcher => sub { 
          # ... code to get the url in $_[0] ...
      }
  )->cssRules->[0];

  $import_rule->href;  # 'print.css'
  $import_rule->media; # a CSS::DOM::MediaList (array ref)
  $import_rule->styleSheet; # a CSS::DOM object

=head1 DESCRIPTION

This module implements CSS C<@import> rules for L<CSS::DOM>. It inherits 
from
L<CSS::DOM::Rule> and implements
the CSSImportRule DOM interface.

=head1 METHODS

=over 4

=item href

Returns the @import rule's URL.

=item media

Returns the MediaList associated with the @import rule (or a plain list in
list context). This defaults to an
empty list. You can pass a comma-delimited string to the MediaList's
C<mediaText> method to set it.

=item styleSheet

This returns the style sheet object, if available. Otherwise it returns an
empty list (this occurs if C<url_fetcher> is not provided or if it returns
undef).

=back

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Rule>

L<CSS::DOM::MediaList>
