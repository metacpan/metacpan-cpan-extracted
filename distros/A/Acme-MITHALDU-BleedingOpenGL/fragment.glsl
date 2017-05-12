uniform vec4 surfacecolor;

void main (void)
{
   float v = 2.0 * gl_TexCoord[0].y;
   v = 1.01 - abs(1.0 - v);  // Some cards have a rounding error
   gl_FragColor = vec4(v,v,v, 1.0) * surfacecolor;
}
