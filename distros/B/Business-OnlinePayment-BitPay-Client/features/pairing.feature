Feature: pairing with bitpay
  In order to access bitpay
  It is required that the library
  Is able to pair successfully

  Scenario: the client has a correct pairing code
    Given the user pairs with BitPay with a valid pairing code
    Then the user is paired with BitPay
  
  Scenario: the client initiates pairing
    Given the user requests a client-side pairing
    Then they will receive a claim code
  
  Scenario: the client has a bad pairing code
    Given the user fails to pair with <code>
    Then they will receive an error matching <message>
    Examples:
      | code       | message                       |
      | "a1b2c3d"  | "500: Unable to create token" |
      | "a1b2c3d4" | "Pairing code is not legal"   |
    
