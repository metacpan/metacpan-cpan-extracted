unsigned char whitespace[256] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, // 00-15
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 16-31
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 32-47  "'" 39, "(" 40, ")" 41, "-" 45, "." 46,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 48-63 DIGIT 48-57
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 64-79 ALPHA 65-90
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 80-95 "_" 95,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 96-111 alpha 97-122
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 112-127 "~" 126,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 128-143
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 144-159
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 160-175
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 176-191
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 192-207
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 208-223
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 224-239
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  // 240-255
};

// not utf safe i belive
perl_scalar* _spaceless(pTHX_ perl_scalar* scalar_string)
{
    if( !(is_scalar_string(scalar_string)) || get_scalar_string_length(scalar_string) == 0  ){
        return(create_scalar_from_scalar(scalar_string));
    }
    
    void*   src_buffer = (void*)get_scalar_string(scalar_string);
    size_t  src_buffer_length = get_scalar_string_length(scalar_string);
    U32     is_utf8 = is_scalar_utf8(scalar_string);
    
    size_t  src_offset = 0;
    
    void*   dst_buffer = malloc(src_buffer_length);
    size_t  dst_offset = 0;
    
    bool    space = true;
    size_t  copy_offset = 0;
    
    for( src_offset = 0; src_offset < src_buffer_length; src_offset++ )
    {
        unsigned char current_char = *(unsigned char*)(src_buffer + src_offset);
        
        if( current_char == '<' )
        {
            if( space )
            {
                copy_offset = src_offset;
            }
            space = false;
        }
        else if( current_char == '>' )
        {
            size_t copy_bytes = src_offset  + 1 - copy_offset;

            memcpy( dst_buffer + dst_offset, src_buffer + copy_offset, copy_bytes );
            
            dst_offset += copy_bytes;

            copy_offset = src_offset + 1;
            space = true;
        }
        else if( is_utf8 )
        {
            if(( current_char & 0x80 )== 0 ){
                // ASCII
            }
            else if(( current_char & 0xE0 ) == 0xC0 && src_offset + 2 <= src_buffer_length ){
                // 2 bytes
                src_offset += 2-1;
            }
            else if((current_char & 0xF0) == 0xE0 && src_offset + 3 <= src_buffer_length ){
                // 3 bytes
                src_offset += 3-1;
            }
            else if((current_char & 0xF8 ) == 0xF0 && src_offset + 4 <= src_buffer_length ){
                // 4 bytes
                src_offset += 4-1;
            }
            else if((current_char & 0xFC) == 0xF8 && src_offset + 5 <= src_buffer_length ){
                // 5 bytes
                src_offset += 5-1;
            }
            else if((current_char & 0xFE)== 0xFC && src_offset + 6 <= src_buffer_length ){
                // 6 bytes
                src_offset += 6-1;
            }
            else
            {
                croak("Corrupted UTF8 data");
            }
            space = false; // here we possibly should check for utf8 spaces
        }
        else if( whitespace[current_char] != 1 ) 
        {
            space = false;
        }
    }
    
    if( !space )
    {
        size_t copy_bytes = src_buffer_length - copy_offset;
    
        if( copy_bytes > 0 )
        {
            if( dst_offset != copy_offset )
            {
                memcpy( dst_buffer + dst_offset, src_buffer + copy_offset, copy_bytes );
            }
            dst_offset += copy_bytes;
        }
    }

    perl_scalar* result = create_scalar_from_scalar(scalar_string);
    set_scalar_string_sized(result, dst_buffer, dst_offset);
    free(dst_buffer);
    return result;
}

