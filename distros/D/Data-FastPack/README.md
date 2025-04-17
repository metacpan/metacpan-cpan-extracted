- encode\_message
- encode\_fastpack

    Encodes an array of fast pack message structures into an buffer

    Buffer is aliased and is an in/out parameter. Encoded data is appended to the buffer.

    Inputs is an array of message structure (also array refs). Array is consumed 

    An optional limit can be sepecified on how many messages to encode in a single call

    Returns the number of bytes encoded

- decode\_message
- decode\_fastpack

    Consumes data from an input buffer and decodes it into 0 or more messages.
    Buffer is aliased and is an in/out parameter
    Decoded messages are added to the dereferenced output array
    An optional limit of message count can be specified.

    Returns the number of bytes consumed during decoding. I a message could not be
    decoded, 0 bytes are consumed.

    ```
    buffer (aliased) 
    output (array ref)
    limit (numeric)

    return (byte count)
    ```
