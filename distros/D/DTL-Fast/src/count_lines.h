/* would be better to copy data only on occurance, not every char */
perl_scalar* _count_lines(pTHX_ perl_scalar* scalar_string){

    if( !(is_scalar_string(scalar_string)) || get_scalar_string_length(scalar_string) == 0  ){
        return create_scalar_from_int(0);
    }

    char*   src_buffer = get_scalar_string(scalar_string);
    size_t  src_length = get_scalar_string_length(scalar_string);
    U32     is_utf8 = is_scalar_utf8(scalar_string);
    
    size_t  src_offset = 0;
    int     lines_number = 0;
    
    while( src_offset < src_length ){
        char current_char = *(src_buffer + src_offset);

        if( current_char == '\n' ){
            lines_number++;
            src_offset++;
        }
        else if(is_utf8){
            // UTF8 char skip
            if(( current_char & 0x80 )== 0 ){
                // ASCII
                src_offset++;
            }
            else if(( current_char & 0xE0 ) == 0xC0 && src_offset + 2 <= src_length ){
                // 2 bytes
                src_offset+=2;
            }
            else if((current_char & 0xF0) == 0xE0 && src_offset + 3 <= src_length ){
                // 3 bytes
                src_offset+=3;
            }
            else if((current_char & 0xF8 ) == 0xF0 && src_offset + 4 <= src_length ){
                // 4 bytes
                src_offset+=4;
            }
            else if((current_char & 0xFC) == 0xF8 && src_offset + 5 <= src_length ){
                // 5 bytes
                src_offset+=5;
            }
            else if((current_char & 0xFE)== 0xFC && src_offset + 6 <= src_length ){
                // 6 bytes
                src_offset+=6;
            }
            else
            {
                croak("Corrupted UTF8 data");
            }
        }
        else // non utf symbol
        {
            src_offset++;
        }
    }

    return create_scalar_from_int(lines_number);
}

