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
bool SB_PARSE_MATCH_STR_FN(secret_buffer_parse *parse, SB_PATTERN_EL_TYPE *pattern, size_t pattern_len, int flags) {
   bool reverse=  0 != (flags & SECRET_BUFFER_MATCH_REVERSE);
   bool multi=    0 != (flags & SECRET_BUFFER_MATCH_MULTI);
   bool anchored= 0 != (flags & SECRET_BUFFER_MATCH_ANCHORED);
   bool negate=   0 != (flags & SECRET_BUFFER_MATCH_NEGATE);
   bool consttime=0 != (flags & SECRET_BUFFER_MATCH_CONST_TIME);
   bool anchor_fail= false;
   bool encoding_error= false;
   U8 *ret_pos= NULL, *ret_lim= NULL,
       ret_pos_bit= 0, ret_lim_bit= 0;
   /* U8 *orig= parse->pos; */

   if (!pattern_len) {
      if (reverse)
         parse->pos= parse->lim;
      else
         parse->lim= parse->pos;
      return true;
   }

   if (!reverse) {
      /* When operating in consttime mode, some matches are "fake" and should be ignored until
       * we reach "real_search_pos". Currently the pointer is enough, no need for the pos_bit. */
      U8 *real_search_pos= parse->pos;
      int first_cp= *pattern;
      while (parse->pos < parse->lim) {
         /* search_pos keeps track of where this iteration started, and next_search_pos
          * may get set during the match to indicate we need to backtrack the parse->pos */
         U8 *search_pos= parse->pos, search_pos_bit= parse->pos_bit;
         U8 *next_char_pos, next_char_pos_bit;
         bool matched;
         int cp= sb_parse_next_codepoint(parse);
         #define SB_HANDLE_ENCODING_ERROR { \
            if (!encoding_error) { \
               encoding_error= true; \
               /* record the location of the encoding error as if we stopped there */ \
               ret_pos=     parse->pos; \
               ret_pos_bit= parse->pos_bit; \
               ret_lim=     parse->lim; \
               ret_lim_bit= parse->lim_bit; \
               if (!consttime) /* consttime keeps going */ \
                  break; \
            } \
            ++parse->pos; /* ensure forward progress for consttime */ \
         }
         if (cp < 0) SB_HANDLE_ENCODING_ERROR
         next_char_pos=     parse->pos;
         next_char_pos_bit= parse->pos_bit;
         matched= cp == first_cp;
         if ((matched || consttime) && pattern_len > 1) {
            SB_PATTERN_EL_TYPE *pat_pos= pattern+1, *pat_lim= pattern + pattern_len;
            U8 *next_potential_pos= NULL, next_potential_pos_bit= 0;
            while (parse->pos < parse->lim && pat_pos < pat_lim) {
               U8 *at_pos= parse->pos, at_pos_bit= parse->pos_bit;
               cp= sb_parse_next_codepoint(parse);
               if (cp < 0) SB_HANDLE_ENCODING_ERROR
               /* speed up outer loop by checking for whether this character could be the start
                  of the next match */
               if (cp == first_cp && !next_potential_pos) {
                  next_potential_pos=     at_pos;
                  next_potential_pos_bit= at_pos_bit;
               }
               if (cp != *pat_pos) {
                  matched= false;
                  if (!consttime)
                     break;
               }
               ++pat_pos;
            }
            if (pat_pos < pat_lim)
               matched= false;
            /* If not a match, backtrack to wherever the next match could start. */
            if (!matched && next_potential_pos) {
               parse->pos=     next_potential_pos;
               parse->pos_bit= next_potential_pos_bit;
            }
         }
#if 0
         if (consttime) {
            warn(" @%2d matched=%d parse->pos=%d real_search_pos=%d ret_pos=%d ret_lim=%d anchor_fail=%d",
               (int)(search_pos-orig), (int)matched, (int)(parse->pos-orig), (int)(real_search_pos-orig),
               (int)(ret_pos? ret_pos-orig : -1), (int)(ret_lim? ret_lim-orig : -1), (int)anchor_fail);
         }
#endif
         #undef SB_HANDLE_ENCODING_ERROR
         /* Code below does not set return values unless `search_pos >= real_search_pos`
          * so that the consttime busywork iterations don't change any return-value state.
          */
         /* Found the goal? (match, or negated match) */
         if (matched != negate) {
            /* The desired (multi?)match begins here, unless it already began */
            if (!ret_pos && search_pos >= real_search_pos) {
               ret_pos=     search_pos;
               ret_pos_bit= search_pos_bit;
            }
            /* It also ends here if multi is false, unless already set */
            if (!multi && !ret_lim && search_pos >= real_search_pos) {
               /* negative matches end at the character following search_pos */
               if (negate) {
                  ret_lim=     next_char_pos;
                  ret_lim_bit= next_char_pos_bit;
               } else {
                  ret_lim=     parse->pos;
                  ret_lim_bit= parse->pos_bit;
               }
               if (!consttime || anchored)
                  break;
            }
         }
         /* If not a match (or matches but negated) and the multi-match was started,
          * search_pos is the end of the multi-match. */
         else if (multi && ret_pos && !ret_lim) {
            if (search_pos >= real_search_pos) {
               ret_lim=     search_pos;
               ret_lim_bit= search_pos_bit;
               if (!consttime)
                  break;
            }
         }
         else if (anchored) { /* not our goal, anchored, and not multi-match */
            if (!ret_pos) {
               anchor_fail= true;
               /* return essentially the original value of 'parse' */
               ret_pos=     search_pos;
               ret_pos_bit= search_pos_bit;
               ret_lim=     parse->lim;
               ret_lim_bit= parse->lim_bit;
            }
            /* only need to waste time if consttime with multiple matches */
            if (!(consttime && multi))
               break;
         }
         /* constant time iteration always resumes at the following character */
         if (consttime) {
            if (search_pos >= real_search_pos)
               real_search_pos= parse->pos;
            parse->pos=     next_char_pos;
            parse->pos_bit= next_char_pos_bit;
         }
      }
      /* If loop exited due to end of input and multi-match was in progress, mark the end */
      if (multi && ret_pos && !ret_lim) {
         ret_lim=     parse->lim;
         ret_lim_bit= parse->lim_bit;
      }
   }
   /* Else do the above in reverse from end of parse span */
   else {
      /* When operating in consttime mode, some matches are "fake" and should be ignored until
       * we reach "real_search_pos". */
      U8 *real_search_lim= parse->lim;
      int last_cp= pattern[pattern_len-1];
      while (parse->pos < parse->lim) {
         U8 *search_lim= parse->lim, search_lim_bit= parse->lim_bit;
         U8 *next_char_lim, next_char_lim_bit;
         bool matched;
         int cp= sb_parse_prev_codepoint(parse);
         #define SB_HANDLE_ENCODING_ERROR { \
            if (!encoding_error) { \
               encoding_error= true; \
               /* record the location of the encoding error as if we stopped there */ \
               ret_pos=     parse->pos; \
               ret_pos_bit= parse->pos_bit; \
               ret_lim=     parse->lim; \
               ret_lim_bit= parse->lim_bit; \
               if (!consttime) /* consttime keeps going */ \
                  break; \
            } \
            --parse->lim; /* ensure progress for consttime */ \
         }
         if (cp < 0) SB_HANDLE_ENCODING_ERROR
         next_char_lim=     parse->lim;
         next_char_lim_bit= parse->lim_bit;
         matched= cp == last_cp;
         if ((matched || consttime) && pattern_len > 1) {
            SB_PATTERN_EL_TYPE *pat_lim= pattern + pattern_len - 1; /* final char already matched */
            U8 *next_potential_lim= NULL, next_potential_lim_bit= 0;
            while (parse->pos < parse->lim && pattern < pat_lim) {
               U8 *at_lim= parse->lim, at_lim_bit= parse->lim_bit;
               cp= sb_parse_prev_codepoint(parse);
               if (cp < 0) SB_HANDLE_ENCODING_ERROR
               /* if const time is not requested, speed up outer loop by checking for whether
                * this character could be the start of the next match */
               if (cp == last_cp && !next_potential_lim) {
                  next_potential_lim=     at_lim;
                  next_potential_lim_bit= at_lim_bit;
               }
               if (cp != pat_lim[-1]) {
                  matched= false;
                  if (!consttime)
                     break;
               }
               --pat_lim;
            }
            if (pattern < pat_lim)
               matched= false;
            /* If not a match, backtrack to wherever the next match could start. */
            if (!matched && next_potential_lim) {
               parse->lim=     next_potential_lim;
               parse->lim_bit= next_potential_lim_bit;
            }
         }
#if 0
         if (!anchored && !multi) {
            warn(" @%2d matched=%d parse->lim=%d real_search_lim=%d ret_pos=%d ret_lim=%d anchor_fail=%d",
               (int)(search_lim-orig-1), (int)matched, (int)(parse->lim-orig), (int)(real_search_lim-orig),
               (int)(ret_pos? ret_pos-orig : -1), (int)(ret_lim? ret_lim-orig : -1), (int)anchor_fail);
         }
#endif
         #undef SB_HANDLE_ENCODING_ERROR
         /* Code below does not set return values unless `search_pos >= real_search_pos`
          * so that the consttime busywork iterations don't change any return-value state.
          */
         /* Found the goal? (match, or negated match) */
         if (matched != negate) {
            /* The desired (multi?)match begins here, unless it already began */
            if (!ret_lim && search_lim <= real_search_lim) {
               ret_lim=     search_lim;
               ret_lim_bit= search_lim_bit;
            }
            /* It also ends here if multi is false, unless already set */
            if (!multi && !ret_pos && search_lim <= real_search_lim) {
               /* negative matches end at the character following search_pos */
               if (negate) {
                  ret_pos=     next_char_lim;
                  ret_pos_bit= next_char_lim_bit;
               } else {
                  ret_pos=     parse->lim;
                  ret_pos_bit= parse->lim_bit;
               }
               if (!consttime || anchored)
                  break;
            }
         }
         /* If not a match (or matches but negated) and the multi-match was started,
          * search_lim is the front of the multi-match. */
         else if (multi && ret_lim && !ret_pos) {
            if (search_lim <= real_search_lim) {
               ret_pos=     search_lim;
               ret_pos_bit= search_lim_bit;
               if (!consttime)
                  break;
            }
         }
         else if (anchored) { /* not our goal, anchored, and not multi-match */
            if (!ret_lim) {
               anchor_fail= true;
               /* return essentially the original value of 'parse' */
               ret_lim=     search_lim;
               ret_lim_bit= search_lim_bit;
               ret_pos=     parse->pos;
               ret_pos_bit= parse->pos_bit;
            }
            /* only need to waste time if consttime with multiple matches */
            if (!(consttime && multi))
               break;
         }
         /* constant time iteration always resumes at the following character */
         if (consttime) {
            if (search_lim <= real_search_lim)
               real_search_lim= parse->lim;
            parse->lim=     next_char_lim;
            parse->lim_bit= next_char_lim_bit;
         }
      }
      /* If loop exited due to end of input and multi-match was in progress, mark the end */
      if (multi && ret_lim && !ret_pos) {
         ret_pos=     parse->pos;
         ret_pos_bit= parse->pos_bit;
      }
   }
   /* If they are both set, overwrite parse and maybe return true.
    * Otherwise, return false with the existing state of parse. */
   if (ret_pos && ret_lim) {
      parse->pos=     ret_pos;
      parse->pos_bit= ret_pos_bit;
      parse->lim=     ret_lim;
      parse->lim_bit= ret_lim_bit;
      return !encoding_error && !anchor_fail;
   }
   return false;
}
