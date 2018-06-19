package Data::Format 0.3;
1;

=encoding utf8

=head1 NAME

Data::Format - A data formating module.

=head1 SYNOPSIS

Module that validate and sanitize data like money and IP adressess.

=head1 Utilities

=head2 Sanitizing

=item Money

    % use Data::Format::Sanitize::Number ':money';

    % money 385.00;                     # '385,00'
    % money 385000;                     # '385.000,00'
    % money 3850000;                    # '3.850.000,00'
    % money 3850000.5;                  # '3.850.000,5'
    % money 3850000.56;                 # '3.850.000,56'
    % money 3850000.56665;              # '3.850.000,56665'

    % money_integer 385;                # '385'
    % money_integer 385000;             # '385.000'
    % money_integer 3850000;            # '3.850.000'
    % money_integer 3850000.00;         # '3.850.000'
    % money_integer 3850000.5646;       # '3.850.000'

    % money_decimal;                    # ',00'
    % money_decimal 385;                # ',385'
    % money_decimal 5465564;            # ',5465564'

    % money_to_int '385,00';            # 385.00
    % money_to_int '385.000,00';        # 385000
    % money_to_int '3.850.000,00';      # 3850000
    % money_to_int '3.850.000,5';       # 3850000.5
    % money_to_int '3.850.000,56';      # 3850000.56
    % money_to_int '3.850.000,56665';   # 3850000.56665

=head2 Validating

Powerful functions to validate data formats

=item Money

    % use Data::Format::Validate::Number ':money';

    % looks_like_money '3.850.000,5';   # 1
    % looks_like_money '3.850.000,56';  # 1

    % looks_like_money '385,,00';       # 0
    % looks_like_money '3e85,0e0';      # 0

=item IP (ipv4)

    % use Data::Format::Validate::String ':ip';

    % looks_like_ipv4 '127.0.0.1';        # 1
    % looks_like_ipv4 '192.168.0.1';      # 1
    % looks_like_ipv4 '255.255.255.255';  # 1

    % looks_like_ipv4 '255255255255';     # 0
    % looks_like_ipv4 '255.255.255.256';  # 0

=item IP (ipv6)

    % use Data::Format::Validate::String ':ip';

    % looks_like_ipv6 '1762:0:0:0:0:B03:1:AF18';                  # 1
    % looks_like_ipv6 '1762:ABC:464:4564:0:BA03:1000:AA1F';       # 1
    % looks_like_ipv6 '1762:4546:A54f:d6fd:5455:B03:1fda:dFde';   # 1

    % looks_like_ipv6 '17620000AFFFB031AF187';                    # 0
    % looks_like_ipv6 '1762:0:0:0:0:B03:AF18';                    # 0
    % looks_like_ipv6 '1762:0:0:0:0:B03:1:Ag18';                  # 0
    % looks_like_ipv6 '1762:0:0:0:0:AFFFB03:1:AF187';             # 0


=back

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/rozcovo/Data-Format

=head1 AUTHOR

Created by Israel Batista <<israel.batista@univem.edu.br>>


__END__