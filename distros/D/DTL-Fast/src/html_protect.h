/* would be better to copy data only on occurance, not every char */
void* _html_protect(pTHX_ perl_scalar* scalar_string){

    if( !(is_scalar_string(scalar_string)) || get_scalar_string_length(scalar_string) == 0  ){
        return(create_scalar_from_scalar(scalar_string));
    }

    char*   src_buffer = get_scalar_string(scalar_string);
    size_t  src_length = get_scalar_string_length(scalar_string);
    U32    is_utf8 = is_scalar_utf8(scalar_string);
    
    // making result escape
    size_t max_dst_length = src_length * 6; // worse case scenario, all symbols being converted
    char* dst_buffer = (char*)malloc(max_dst_length);
    
    // escaping
    size_t src_offset = 0;
    size_t dst_offset = 0;

    while( src_offset < src_length ){
        char current_char = *(src_buffer + src_offset);
        size_t chars_left = src_length - src_offset;

        if( current_char == '&' ){
            memcpy( dst_buffer+ dst_offset, "&amp;", 5);
            dst_offset += 5;
        }
        else if( current_char == '<' ){
            memcpy( dst_buffer+ dst_offset, "&lt;", 4);
            dst_offset += 4;
        }
        else if( current_char == '>' ){
            memcpy( dst_buffer+ dst_offset, "&gt;", 4);
            dst_offset += 4;
        }
        else if( current_char == '\"' ){ 
            memcpy( dst_buffer+ dst_offset, "&quot;", 6);
            dst_offset += 6;
        }
        else if( current_char == '\'' ){
            memcpy( dst_buffer+ dst_offset, "&#39;", 5);
            dst_offset += 5;
        }
        else if(is_utf8){
            // UTF8 rest copy
            if(( current_char & 0x80 )== 0 ){
                // ASCII
                *(dst_buffer+dst_offset) = current_char;
                dst_offset++;
            }
            else if(( current_char & 0xE0 ) == 0xC0 && src_offset + 2 <= src_length ){
                // 2 bytes
                memcpy( dst_buffer+dst_offset, src_buffer + src_offset, 2);
                dst_offset += 2;
                src_offset += 2-1;
            }
            else if((current_char & 0xF0) == 0xE0 && src_offset + 3 <= src_length ){
                // 3 bytes
                memcpy( dst_buffer+dst_offset, src_buffer + src_offset, 3);
                dst_offset += 3;
                src_offset += 3-1;
            }
            else if((current_char & 0xF8 ) == 0xF0 && src_offset + 4 <= src_length ){
                // 4 bytes
                memcpy( dst_buffer+dst_offset, src_buffer + src_offset, 4);
                dst_offset += 4;
                src_offset += 4-1;
            }
            else if((current_char & 0xFC) == 0xF8 && src_offset + 5 <= src_length ){
                // 5 bytes
                memcpy( dst_buffer+dst_offset, src_buffer + src_offset, 5);
                dst_offset += 5;
                src_offset += 5-1;
            }
            else if((current_char & 0xFE)== 0xFC && src_offset + 6 <= src_length ){
                // 6 bytes
                memcpy( dst_buffer+dst_offset, src_buffer + src_offset, 6);
                dst_offset += 6;
                src_offset += 6-1;
            }
            else
            {
                croak("Corrupted UTF8 data");
            }
        }
        else // non utf symbol copy
        {
            *(dst_buffer+dst_offset) = current_char;
            dst_offset++;
        }

        src_offset++;
    }

    perl_scalar* result = create_scalar_from_scalar(scalar_string);
    set_scalar_string_sized(result, dst_buffer, dst_offset);
    free(dst_buffer);
    return result;
}

