#ifndef _TWODARRAY_H_
#define _TWODARRAY_H_

template <class T>
class TwoDArray
{
public:
  TwoDArray(int row, int col) : m_row(row),
                                       m_col(col),
                                       m_data((row != 0 && col != 0) ? new T[row * col] : NULL){}

  TwoDArray(const TwoDArray& src) : m_row(src.m_row),
                                                  m_col(src.m_col),
                                                  m_data((src.m_row != 0 && src.m_col != 0) ? new T[src.m_row * src.m_col] : NULL)
  {
    for(int r = 0;r < m_row; ++r)
      for(int c = 0; c < m_col; ++c)
        (*this)[r][c] = src[r][c];
  }

  ~TwoDArray()
  {
    if(m_data)
      delete []m_data;
  }
  
  inline T* operator[](int i) { return (m_data + (m_col * i)); }

  inline T const*const operator[](int i) const {return (m_data + (m_col * i)); }


private:
  TwoDArray& operator=(const TwoDArray&);
  const int m_row;
  const int m_col;
  T* m_data; 
};

#endif //_TWODARRAY_H_
