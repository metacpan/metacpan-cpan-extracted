c Zoom in and out, and move picture around
c
	subroutine pgzoom(xmin,xmax,ymin,ymax)
c
	character val
c
	write(*,*)
	write(*,*) '** Move cursor into the graphic screen **'
	write(*,*)
	write(*,*) 'i - zoom in,          o - zoom out'
	write(*,*) 'k - move image up,    j - move image down'
	write(*,*) 'l - move image right, h - move image left'
	write(*,*)
	write(*,*) '** Press any other key to leave **'
	write(*,*)
c
	read(*,'(a)') val
c
c Zoom in
	  if (val.eq.'i') then
	    dx = (xmax - xmin)/10
	    dy = (ymax - ymin)/10
c	    xmin = xmin + dx
c           xmax = xmax - dx
            xmax = xmax - 2.0*dx
            ymin = ymin + dy
            ymax = ymax - dy
	  endif
c Zoom out
	  if (val.eq.'o') then
	    dx = -(xmax - xmin)/8
	    dy = -(ymax - ymin)/8
	    xmin = xmin + dx
            xmax = xmax - dx
            ymin = ymin + dy
            ymax = ymax - dy
	  endif
c Move image down
	  if (val.eq.'j') then
            dy = (ymax - ymin)/10
	    ymin = ymin - dy
	    ymax = ymax - dy
          endif
c Move image up
	  if (val.eq.'k') then
            dy = (ymax - ymin)/10
	    ymin = ymin + dy
            ymax = ymax + dy
          endif
c Move image to the right
	  if (val.eq.'l') then
            dx = (xmax - xmin)/10
            xmin = xmin - dx
            xmax = xmax - dx
          endif
c Move image to the left
          if (val.eq.'h') then
	    dx = (xmax - xmin)/10
            xmin = xmin + dx
            xmax = xmax + dx
          endif
c
	return
	end
