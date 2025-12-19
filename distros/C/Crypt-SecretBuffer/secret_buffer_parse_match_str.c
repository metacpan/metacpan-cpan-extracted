/* included twice for different pattern element types */

/* This scans through a parse span codepoint by codepoint looking for the sequence
 * passed in the 'pattern' array.
 *  - If flag 'anchored' is set, it stops the loop if the match doesn't happen
 *    on the first iteration.
 *  - If flag 'reverse' is set, it iterates backward over the span's codepoints
 *    comparing to pattern in reverse.
 *  - If flag 'multi' is set, it looks for a contiguous span of matches
 *    (mostly useful when the pattern is a single character)
 *  - If flag 'negate' is set, it negates the check of whether the pattern
 *    matched.  For 'multi', this means it returns the span *until* the first
 *    match of the pattern begins.
 */
bool SB_PARSE_MATCH_STR_FN(secret_buffer_parse *parse, SB_PATTERN_EL_TYPE *pattern, int pattern_len, int flags) {
   bool reverse=  0 != (flags & SECRET_BUFFER_MATCH_REVERSE);
   bool multi=    0 != (flags & SECRET_BUFFER_MATCH_MULTI);
   bool anchored= 0 != (flags & SECRET_BUFFER_MATCH_ANCHORED);
   bool negate=   0 != (flags & SECRET_BUFFER_MATCH_NEGATE);
   if (!pattern_len) {
      if (reverse)
         parse->pos= parse->lim;
      else
         parse->lim= parse->pos;
      return true;
   }

   if (!reverse) {
      U8 *multi_pos= NULL, multi_pos_bit;
      while (parse->pos < parse->lim) {
         U8 *loop_pos= parse->pos, loop_pos_bit= parse->pos_bit;
         U8 *backtrack_pos= NULL, backtrack_pos_bit;
         SB_PATTERN_EL_TYPE *pat_pos= pattern, *pat_lim= pattern + pattern_len;
         int cp= sb_parse_next_codepoint(parse);
         if (cp < 0)
            return false;
         if (cp == *pat_pos) {
            ++pat_pos;
            while (parse->pos < parse->lim && pat_pos < pat_lim) {
               U8 *at_pos= parse->pos, at_pos_bit= parse->pos_bit;
               cp= sb_parse_next_codepoint(parse);
               if (cp < 0)
                  return false;
               if (cp == *pattern && !backtrack_pos) {
                  backtrack_pos= at_pos;
                  backtrack_pos_bit= at_pos_bit;
               }
               if (cp != *pat_pos)
                  break;
               pat_pos++;
            }
         }
         if ((pat_pos == pat_lim) != negate) {
            // Found the goal (match, or negated match)
            if (!multi) {
               parse->lim= parse->pos;
               parse->lim_bit= parse->pos_bit;
               parse->pos= loop_pos;
               parse->pos_bit= loop_pos_bit;
               return true;
            }
            // If multi, the desired span begins here, unless it already began
            if (!multi_pos) {
               multi_pos= loop_pos;
               multi_pos_bit= loop_pos_bit;
            }
            // If negated, backtrack to the next potential start of a match,
            // else continue from here.
            if (negate && backtrack_pos) {
               parse->pos= backtrack_pos;
               parse->pos_bit= backtrack_pos_bit;
            }
         }
         // If not a match (or matches but negated) and the span was started,
         // this is the end of the span.
         else if (multi && multi_pos) {
            parse->pos= loop_pos;
            parse->pos_bit= loop_pos_bit;
            break;
         }
         // anchored matches fail immediately
         else if (anchored)
            break;
      }
      if (multi && multi_pos) {
         parse->lim= parse->pos;
         parse->lim_bit= parse->pos_bit;
         parse->pos= multi_pos;
         parse->pos_bit= multi_pos_bit;
         return true;
      }
   }
   // Else do the above in reverse from end of parse span
   else {
      U8 *multi_lim= NULL, multi_lim_bit;
      int pat_last= pattern[pattern_len-1];
      while (parse->pos < parse->lim) {
         U8 *loop_lim= parse->lim, loop_lim_bit= parse->lim_bit;
         U8 *backtrack_lim= NULL, backtrack_lim_bit;
         SB_PATTERN_EL_TYPE *pat_lim= pattern + pattern_len;
         int cp= sb_parse_prev_codepoint(parse);
         if (cp < 0)
            return false;
         if (cp == pat_last) {
            --pat_lim;
            while (parse->pos < parse->lim && pattern < pat_lim) {
               U8 *at_lim= parse->lim, at_lim_bit= parse->lim_bit;
               cp= sb_parse_prev_codepoint(parse);
               if (cp < 0)
                  return false;
               if (cp == pat_last && !backtrack_lim) {
                  backtrack_lim= at_lim;
                  backtrack_lim_bit= at_lim_bit;
               }
               if (cp != pat_lim[-1])
                  break;
               --pat_lim;
            }
         }
         if ((pattern == pat_lim) != negate) {
            // Found the goal (match, or negated match)
            if (!multi) {
               parse->pos= parse->lim;
               parse->pos_bit= parse->lim_bit;
               parse->lim= loop_lim;
               parse->lim_bit= loop_lim_bit;
               return true;
            }
            // If multi, the desired span begins here, unless it already began
            if (!multi_lim) {
               multi_lim= loop_lim;
               multi_lim_bit= loop_lim_bit;
            }
            // If negated, backtrack to the next potential start of a match,
            // else continue from here.
            if (negate && backtrack_lim) {
               parse->lim= backtrack_lim;
               parse->lim_bit= backtrack_lim_bit;
            }
         }
         // If not a match (or matches but negated) and the span was started,
         // this is the end of the span.
         else if (multi && multi_lim) {
            parse->lim= loop_lim;
            parse->lim_bit= loop_lim_bit;
            break;
         }
         // anchored matches fail immediately
         else if (anchored)
            break;
      }
      if (multi && multi_lim) {
         parse->pos= parse->lim;
         parse->pos_bit= parse->lim_bit;
         parse->lim= multi_lim;
         parse->lim_bit= multi_lim_bit;
         return true;
      }
   }
   return false;
}
