/*
 *  Copyright 2015 Matthew Newton
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in
 *      the documentation and/or other materials provided with the
 *      distribution.
 *
 *   3. Neither the name of the copyright holder nor the names of its
 *      contributors may be used to endorse or promote products derived
 *      from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef INCLUDE_HEXDUMP
int hexdump(FILE *fd, void const *data, size_t length, int linelen, int split)
{
	char buffer[512];
	char *ptr;
	const void *inptr;
	int pos;
	int remaining = length;

	inptr = data;
	/*
	 *	Assert that the buffer is large enough. This should pretty much
	 *	always be the case...
	 *
	 *	hex/ascii gap (2 chars) + closing \0 (1 char)
	 *	split = 4 chars (2 each for hex/ascii) * number of splits
	 *
	 *	(hex = 3 chars, ascii = 1 char) * linelen number of chars
	 */
	assert(sizeof(buffer) >= (3 + (4 * (linelen / split)) + (linelen * 4)));

	/*
	 *	Loop through each line remaining
	 */
	while (remaining > 0) {
		int lrem;
		int splitcount;
		ptr = buffer;

		/*
		 *	Loop through the hex chars of this line
		 */
		lrem = remaining;
		splitcount = 0;
		for (pos = 0; pos < linelen; pos++) {

			/* Split hex section if required */
			if (split == splitcount++) {
				sprintf(ptr, "  ");
				ptr += 2;
				splitcount = 1;
			}

			/* If still remaining chars, output, else leave a space */
			if (lrem) {
				sprintf(ptr, "%02x ", *((unsigned char *) inptr + pos));
				lrem--;
			} else {
				sprintf(ptr, "   ");
			}
			ptr += 3;
		}

		*ptr++ = ' ';
		*ptr++ = ' ';

		/*
		 *	Loop through the ASCII chars of this line
		 */
		lrem = remaining;
		splitcount = 0;
		for (pos = 0; pos < linelen; pos++) {
			unsigned char c;

			/* Split ASCII section if required */
			if (split == splitcount++) {
				sprintf(ptr, "  ");
				ptr += 2;
				splitcount = 1;
			}

			if (lrem) {
				c = *((unsigned char *) inptr + pos);
				if (c > 31 && c < 127) {
					sprintf(ptr, "%c", c);
				} else {
					sprintf(ptr, ".");
				}
				lrem--;
		/*
		 *	These two lines would pad out the last line with spaces
		 *	which seems a bit pointless generally.
		 */
		/*
			} else {
				sprintf(ptr, " ");
		*/

			}
			ptr++;
		}

		*ptr = '\0';
		fprintf(fd, "%s\n", buffer);

		inptr += linelen;
		remaining -= linelen;
	}

	return 0;
}
#endif
