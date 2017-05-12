package CSS::DOM::RuleList;

$VERSION = '0.16';

require CSS::DOM::Array;
@ISA = 'CSS::DOM::Array';

                              !()__END__()!

=head1 NAME

CSS::DOM::RuleList - Rule list class for CSS::DOM

=head1 VERSION

Version 0.16

=head1 DESCRIPTION

This module implements rule lists for L<CSS::DOM>. It implements the
CSSRuleList DOM interface.

This simply inherits from L<CSS::DOM::Array> without adding anything
extra.

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Array>
